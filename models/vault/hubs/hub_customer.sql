{{ config(materialized='table') }}

with staging_data as (

    select
        customer_hk,
        customer_id,
        load_date,
        record_source
    from {{ ref('stg_customer') }}

),

distinct_records as (

    select
        customer_hk,
        customer_id,
        load_date,
        record_source,
        row_number() over (partition by customer_hk order by load_date asc) as row_num
    from staging_data

)

select
    customer_hk,
    customer_id,
    load_date,
    record_source
from distinct_records
where row_num = 1
  and customer_id is not null