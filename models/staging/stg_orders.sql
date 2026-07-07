{{ config(materialized='view') }}
with source_data as (select * from {{ source('raw_source', 'raw_orders') }}),
final as (
    select
        lower(md5(cast(trim(o_orderkey) as varchar(100)))) as order_hk,
        o_orderkey as order_id,
        o_custkey as customer_id,
        o_orderstatus as order_status,
        o_totalprice as total_price,
        o_orderdate as order_date,
        o_orderpriority as order_priority,
        o_clerk as clerk,
        o_shippriority as ship_priority,
        o_comment as comment,
        current_timestamp() as load_date,
        'RAW_ORDERS' as record_source
    from source_data
)
select * from final