{{ config(materialized='view') }}
with source_data as (select * from {{ source('raw_source', 'raw_supplier') }}),
final as (
    select
        lower(md5(cast(s_suppkey as string))) as supplier_hk,
        s_suppkey as supplier_id,
        s_name as name,
        s_address as address,
        s_nationkey as nation_id,
        s_phone as phone,
        s_acctbal as account_balance,
        s_comment as comment,
        current_timestamp() as load_date,
        'RAW_SUPPLIER' as record_source
    from source_data
)
select * from final