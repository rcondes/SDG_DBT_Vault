-- stg_region.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_region') }}
),

final as (
  select
    r_regionkey as region_id,
    r_name as region_name,
    r_comment as comment,
    r_load_timestamp as load_timestamp,
    r_version as version,
    'raw_region' as record_source
  from source_data
)

select * from final
