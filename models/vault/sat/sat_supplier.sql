{{ config(
    materialized='incremental',
    unique_key='sat_hk'
) }}

with source_data as (
    select * from {{ ref('stg_supplier') }}
),

staging as (
    select
        supplier_id,
        supplier_name,
        supplier_address,
        nation_id,
        supplier_phone,
        account_balance,
        supplier_comment,
        load_timestamp as valid_from,
        
        {{ dbt_utils.generate_surrogate_key([
            'supplier_id', 
            'load_timestamp'
        ]) }} as sat_hk,

        {{ dbt_utils.generate_surrogate_key([
            'supplier_name', 
            'supplier_address', 
            'nation_id', 
            'supplier_phone', 
            'account_balance', 
            'supplier_comment'
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
        s.supplier_id,
        s.supplier_name,
        s.supplier_address,
        s.nation_id,
        s.supplier_phone,
        s.account_balance,
        s.supplier_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    left join current_sat cs on s.supplier_id = cs.supplier_id
    where cs.supplier_id is null
),

changed_new_versions as (
    select
        s.sat_hk,
        s.supplier_id,
        s.supplier_name,
        s.supplier_address,
        s.nation_id,
        s.supplier_phone,
        s.account_balance,
        s.supplier_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    inner join current_sat cs on s.supplier_id = cs.supplier_id
    where s.hashdiff != cs.hashdiff
),

changed_old_versions as (
    select
        cs.sat_hk,
        cs.supplier_id,
        cs.supplier_name,
        cs.supplier_address,
        cs.nation_id,
        cs.supplier_phone,
        cs.account_balance,
        cs.supplier_comment,
        cs.valid_from,
        s.valid_from as valid_to,
        cs.hashdiff
    from current_sat cs
    inner join staging s on cs.supplier_id = s.supplier_id
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
    supplier_id,
    supplier_name,
    supplier_address,
    nation_id,
    supplier_phone,
    account_balance,
    supplier_comment,
    valid_from,
    cast('9999-12-31 23:59:59' as timestamp) as valid_to,
    hashdiff
from staging

{% endif %}