{{ config(materialized='incremental', unique_key='sat_hk') }}

with source_data as (
    select * from {{ ref('stg_nation') }}
),

staging as (
    select
        nation_id,
        nation_name,
        region_id,
        nation_comment,
        load_timestamp as valid_from,
        
        -- PK del Satélite
        {{ dbt_utils.generate_surrogate_key([
            'nation_id', 
            'load_timestamp'
        ]) }} as sat_hk,

        -- Hash de atributos para detectar cambios
        {{ dbt_utils.generate_surrogate_key([
            'nation_name', 
            'region_id', 
            'nation_comment'
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
        s.nation_id,
        s.nation_name,
        s.region_id,
        s.nation_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    left join current_sat cs on s.nation_id = cs.nation_id
    where cs.nation_id is null
),

changed_new_versions as (
    select
        s.sat_hk,
        s.nation_id,
        s.nation_name,
        s.region_id,
        s.nation_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    inner join current_sat cs on s.nation_id = cs.nation_id
    where s.hashdiff != cs.hashdiff
),

changed_old_versions as (
    select
        cs.sat_hk,
        cs.nation_id,
        cs.nation_name,
        cs.region_id,
        cs.nation_comment,
        cs.valid_from,
        s.valid_from as valid_to,
        cs.hashdiff
    from current_sat cs
    inner join staging s on cs.nation_id = s.nation_id
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
    nation_id,
    nation_name,
    region_id,
    nation_comment,
    valid_from,
    cast('9999-12-31 23:59:59' as timestamp) as valid_to,
    hashdiff
from staging

{% endif %}