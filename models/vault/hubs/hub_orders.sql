-- models/vault/hubs/hub_orders.sql
{{ config(materialized='incremental', unique_key='order_hk', tags=['hub']) }}

with stage_data as (
    select
        lower(md5(cast(order_id as varchar))) as order_hk,
        order_id,
        load_timestamp
    from {{ ref('stg_orders') }}
    where order_id is not null
),

distinct_records as (
    select
        order_hk,
        order_id,
        max(load_timestamp) as load_timestamp
    from stage_data
    group by 1, 2
)

select * from distinct_records

{% if is_incremental() %}
where order_hk not in (select order_hk from {{ this }})
{% endif %}