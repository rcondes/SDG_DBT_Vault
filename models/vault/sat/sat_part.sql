{{ config(
    materialized='incremental',
    unique_key='sat_hk'
) }}

with source_data as (
    select * from {{ ref('stg_part') }}
),

staging as (
    select
        part_id,
        part_name,
        manufacturer,
        brand,
        part_type,
        part_size,
        container,
        retail_price,
        part_comment,
        load_timestamp as valid_from,
        
        {{ dbt_utils.generate_surrogate_key([
            'part_id', 
            'load_timestamp'
        ]) }} as sat_hk,

        {{ dbt_utils.generate_surrogate_key([
            'part_name', 
            'manufacturer', 
            'brand', 
            'part_type', 
            'part_size', 
            'container', 
            'retail_price', 
            'part_comment'
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
        s.part_id,
        s.part_name,
        s.manufacturer,
        s.brand,
        s.part_type,
        s.part_size,
        s.container,
        s.retail_price,
        s.part_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    left join current_sat cs on s.part_id = cs.part_id
    where cs.part_id is null
),

changed_new_versions as (
    select
        s.sat_hk,
        s.part_id,
        s.part_name,
        s.manufacturer,
        s.brand,
        s.part_type,
        s.part_size,
        s.container,
        s.retail_price,
        s.part_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    inner join current_sat cs on s.part_id = cs.part_id
    where s.hashdiff != cs.hashdiff
),

changed_old_versions as (
    select
        cs.sat_hk,
        cs.part_id,
        cs.part_name,
        cs.manufacturer,
        cs.brand,
        cs.part_type,
        cs.part_size,
        cs.container,
        cs.retail_price,
        cs.part_comment,
        cs.valid_from,
        s.valid_from as valid_to,
        cs.hashdiff
    from current_sat cs
    inner join staging s on cs.part_id = s.part_id
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
    part_id,
    part_name,
    manufacturer,
    brand,
    part_type,
    part_size,
    container,
    retail_price,
    part_comment,
    valid_from,
    cast('9999-12-31 23:59:59' as timestamp) as valid_to,
    hashdiff
from staging

{% endif %}