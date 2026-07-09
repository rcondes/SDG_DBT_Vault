{{ config(
    materialized='incremental',
    unique_key='sat_hk'
) }}

with source_data as (
    select * from {{ ref('stg_orders') }}
),

staging as (
    select
        order_id,
        customer_id,
        order_status,
        total_price,
        order_date,
        order_priority,
        clerk,
        ship_priority,
        order_comment,
        load_timestamp as valid_from,
        
        {{ dbt_utils.generate_surrogate_key([
            'order_id', 
            'load_timestamp'
        ]) }} as sat_hk,

        {{ dbt_utils.generate_surrogate_key([
            'customer_id',
            'order_status', 
            'total_price', 
            'order_date', 
            'order_priority', 
            'clerk', 
            'ship_priority', 
            'order_comment'
        ]) }} as hashdiff

    from source_data
)

{% if is_incremental() %}

, current_sat as (
    select *
    from {{ this }}
    where valid_to = cast('9999-12-31 23:59:59' as timestamp)
),

new_records as (
    select
        s.sat_hk,
        s.order_id,
        s.customer_id,
        s.order_status,
        s.total_price,
        s.order_date,
        s.order_priority,
        s.clerk,
        s.ship_priority,
        s.order_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    left join current_sat cs on s.order_id = cs.order_id
    where cs.order_id is null
),

changed_new_versions as (
    select
        s.sat_hk,
        s.order_id,
        s.customer_id,
        s.order_status,
        s.total_price,
        s.order_date,
        s.order_priority,
        s.clerk,
        s.ship_priority,
        s.order_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    inner join current_sat cs on s.order_id = cs.order_id
    where s.hashdiff != cs.hashdiff
),

changed_old_versions as (
    select
        cs.sat_hk,
        cs.order_id,
        cs.customer_id,
        cs.order_status,
        cs.total_price,
        cs.order_date,
        cs.order_priority,
        cs.clerk,
        cs.ship_priority,
        cs.order_comment,
        cs.valid_from,
        s.valid_from as valid_to,
        cs.hashdiff
    from current_sat cs
    inner join staging s on cs.order_id = s.order_id
    where s.hashdiff != cs.hashdiff
),

final as (
    select * from new_records
    union all
    select * from changed_new_versions
    union all
    select * from changed_old_versions
)

select * from final

{% else %}

select
    sat_hk,
    order_id,
    customer_id,
    order_status,
    total_price,
    order_date,
    order_priority,
    clerk,
    ship_priority,
    order_comment,
    valid_from,
    cast('9999-12-31 23:59:59' as timestamp) as valid_to,
    hashdiff
from staging

{% endif %}