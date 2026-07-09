-- stg_customer.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_customer') }}
),

final as (
  select
    c_custkey as customer_id,
    c_name as customer_name,
    c_address as address,
    c_nationkey as nation_id,
    c_phone as phone,
    c_acctbal as account_balance,
    c_mktsegment as market_segment,
    c_comment as comment,
    c_load_timestamp as load_timestamp,
    c_version as version,
    'raw_customer' as record_source
  from source_data
)

select * from final