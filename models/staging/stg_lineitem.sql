{{ config(materialized='view') }}
with source_data as (select * from {{ source('raw_source', 'raw_lineitem') }}),
final as (
    select
        lower(md5(concat(cast(l_orderkey as string), cast(l_linenumber as string)))) as lineitem_hk,
        l_orderkey as order_id,
        l_partkey as part_id,
        l_suppkey as supplier_id,
        l_linenumber as line_number,
        l_quantity as quantity,
        l_extendedprice as extended_price,
        l_discount as discount,
        l_tax as tax,
        l_returnflag as return_flag,
        l_linestatus as line_status,
        l_shipdate as ship_date,
        l_commitdate as commit_date,
        l_receiptdate as receipt_date,
        l_shipinstruct as ship_instruct,
        l_shipmode as ship_mode,
        l_comment as comment,
        current_timestamp() as load_date,
        'RAW_LINEITEM' as record_source
    from source_data
)
select * from final