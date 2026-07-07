{{ config(materialized='view') }}
with source_data as (select * from {{ source('raw_source', 'raw_customer') }}),
final as (
    select
        lower(md5(cast(c_custkey as string))) as customer_hk,
        c_custkey as customer_id,
        c_name as customer_name,
        c_address as address,
        c_nationkey as nation_id,
        c_phone as phone,
        c_acctbal as account_balance,
        c_mktsegment as market_segment,
        c_comment as comment,
        current_timestamp() as load_date,
        'RAW_CUSTOMER' as record_source
    from source_data
)
select * from final