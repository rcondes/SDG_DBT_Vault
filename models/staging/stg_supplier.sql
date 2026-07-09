-- stg_supplier.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_supplier') }}
),

final as (
  select
    s_suppkey as supplier_id,
    s_name as supplier_name,
    s_address as supplier_address,
    s_nationkey as nation_id,
    s_phone as supplier_phone,
    s_acctbal as account_balance,
    s_comment as supplier_comment,
    s_load_timestamp as load_timestamp,
    s_version as supplier_version,
    'raw_supplier' as record_source
  from 
    source_data
)

select * from final