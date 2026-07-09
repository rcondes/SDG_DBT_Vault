{{ config(materialized='table') }}

with staging_data as (
    select order_hk, order_id, load_date, record_source 
    from {{ ref('stg_orders') }}
),
final as (
    select 
        order_hk, 
        order_id, 
        load_date, 
        record_source
    from (
        select *, row_number() over (partition by order_hk order by load_date desc) as rn
        from staging_data
        where order_hk is not null
    )
    where rn = 1
)
select * from final