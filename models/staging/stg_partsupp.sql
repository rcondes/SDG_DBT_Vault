{{ config(materialized='view') }}
with source_data as (select * from {{ source('raw_source', 'raw_partsupp') }}),
final as (
    select
        lower(md5(concat(cast(ps_partkey as string), cast(ps_suppkey as string)))) as partsupp_hk,
        ps_partkey as part_id,
        ps_suppkey as supplier_id,
        ps_availqty as available_qty,
        ps_supplycost as supply_cost,
        ps_comment as comment,
        current_timestamp() as load_date,
        'RAW_PARTSUPP' as record_source
    from source_data
)
select * from final