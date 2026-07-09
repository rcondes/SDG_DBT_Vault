-- stg_customer.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_customer') }}
),

final as (
  select
    c_custkey as customer_id,
    c_name as customer_name,
    c_address as customer_address,
    c_nationkey as customer_nation_id,
    c_phone as customer_phone,
    c_acctbal as account_balance,
    c_mktsegment as market_segment,
    c_comment as customer_comment,
    c_load_timestamp as load_timestamp,
    c_version as customer_version,
    'raw_customer' as record_source
  from 
    source_data
)

select * from final