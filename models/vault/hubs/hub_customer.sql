{{ config(materialized='table') }}

with staging_data as (
    select customer_hk, customer_id, load_date, record_source 
    from {{ ref('stg_customer') }}
),
final as (
    select 
        customer_hk, 
        customer_id, 
        load_date, 
        record_source
    from (
        select *, row_number() over (partition by customer_hk order by load_date desc) as rn
        from staging_data
        where customer_hk is not null
    )
    where rn = 1
)
select * from final