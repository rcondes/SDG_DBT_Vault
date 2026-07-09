-- stg_partsupp.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_partsupp') }}
),

final as (
  select
    ps_partkey as part_id,
    ps_suppkey as supplier_id,
    ps_availqty as avail_quantity,
    ps_supplycost as supply_cost,
    ps_comment,
    ps_load_timestamp as load_timestamp,
    ps_version,
    'raw_partsupp' as record_source
  from 
    source_data
)

select * from final