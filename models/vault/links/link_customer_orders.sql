{{ config(materialized='table') }}

with staging_data as (

    select
        customer_hk,
        order_hk
    from {{ ref('stg_orders') }}
    where customer_hk is not null 
      and order_hk is not null

),

final as (

    select distinct
        lower(md5(concat_ws('||', customer_hk, order_hk))) as customer_orders_pk,
        customer_hk,
        order_hk,
        current_timestamp() as load_date,
        'SNOWFLAKE.RAW.RAW_ORDERS' as record_source
    from staging_data

)

select * from final