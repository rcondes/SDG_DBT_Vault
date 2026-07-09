-- stg_nation.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_nation') }}
),

final as (
  select
    n_nationkey as nation_id,
    n_name as nation_name,
    n_regionkey as region_id,
    n_comment as comment,
    n_load_timestamp as load_timestamp,
    n_version as nation_version,
    'raw_nation' as record_source
  from 
    source_data
)

select * from final