-- stg_part.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_part') }}
),

final as (
  select
    p_partkey as part_id,
    p_name as part_name,
    p_mfgr as manufacturer,
    p_brand as brand,
    p_type as type,
    p_size as size,
    p_container as container,
    p_retailprice as retail_price,
    p_comment as comment,
    p_load_timestamp as load_timestamp,
    p_version as version,
    'raw_part' as record_source
  from source_data
)

select * from final