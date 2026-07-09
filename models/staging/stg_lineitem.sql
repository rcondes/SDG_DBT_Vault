-- stg_lineitem.sql
{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_source', 'raw_lineitem') }}
),

final as (
  select
    l_orderkey as order_id,
    l_linenumber as line_number,
    l_partkey as part_id,
    l_suppkey as supplier_id,
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
    l_load_timestamp as load_timestamp,
    l_version as li_version,
    'raw_lineitem' as record_source
  from 
    source_data
)

select * from final