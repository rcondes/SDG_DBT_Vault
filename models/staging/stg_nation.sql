{{ config(materialized='view') }}
with source_data as (select * from {{ source('raw_source', 'raw_nation') }}),
final as (
    select
        lower(md5(cast(trim(n_nationkey) as varchar()))) as nation_hk,
        n_nationkey as nation_id,
        n_name as nation_name,
        n_regionkey as region_id,
        n_comment as comment,
        current_timestamp() as load_date,
        'RAW_NATION' as record_source
    from source_data
)
select * from final