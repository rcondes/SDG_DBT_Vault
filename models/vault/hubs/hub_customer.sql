{{ config(materialized='incremental', unique_key='customer_hk', tags=['hub']) }}

with stage_data as (
    select
        lower(md5(cast(customer_id as varchar))) as customer_hk,
        customer_id,
        load_timestamp
    from {{ ref('stg_customer') }}
    where customer_id is not null
),

distinct_records as (
    select
        customer_hk,
        customer_id,
        -- Si el cliente aparece en ambas versiones, nos quedamos con la fecha de carga más nueva
        max(load_timestamp) as load_timestamp
    from stage_data
    group by 1, 2
)

select * from distinct_records

{% if is_incremental() %}
-- En ejecuciones incrementales, solo traemos claves que no existan ya en el HUB
where customer_hk not in (select customer_hk from {{ this }})
{% endif %}