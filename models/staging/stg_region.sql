{{ config(materialized='view') }}
with source_data as (select * from {{ source('raw_source', 'raw_region') }}),
final as (
    select
        lower(md5(cast(trim(r_regionkey) as varchar(100)))) as region_hk,
        r_regionkey as region_id,
        r_name as region_name,
        r_comment as comment,
        current_timestamp() as load_date,
        'RAW_REGION' as record_source
    from source_data
)
select * from final