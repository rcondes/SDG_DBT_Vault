{{ config(materialized='table') }}

with staging_data as (

    select
        order_hk,
        order_id,
        load_date,
        record_source
    from {{ ref('stg_orders') }}

),

distinct_records as (

    select
        order_hk,
        order_id,
        load_date,
        record_source,
        row_number() over (partition by order_hk order by load_date asc) as row_num
    from staging_data

)

select
    order_hk,
    order_id,
    load_date,
    record_source
from distinct_records
where row_num = 1
  and order_id is not null