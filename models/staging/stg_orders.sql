-- stg_orders.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_orders') }}
),

final as (
  select
    o_orderkey as order_id,
    o_custkey as customer_id,
    o_orderstatus as order_status,
    o_totalprice as total_price,
    o_orderdate as order_date,
    o_orderpriority as order_priority,
    o_clerk as clerk,
    o_shippriority as ship_priority,
    o_comment as order_comment,
    o_load_timestamp as load_timestamp,
    o_version as order_version,
    'raw_orders' as record_source
  from 
    source_data
)

select * from final