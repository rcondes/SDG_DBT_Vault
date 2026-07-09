{{ config(materialized='table', tags=['mart']) }}

with sat_customer as (
    select * from {{ ref('sat_customer') }} where valid_to = '9999-12-31 23:59:59.000'
),
-- Calculamos métricas desde las líneas de pedido existentes
customer_metrics as (
    select 
        s.customer_id, 
        count(distinct o.order_id) as total_orders
    from {{ ref('sat_customer') }} s
    left join {{ ref('sat_orders') }} o on s.customer_id = o.customer_id
    group by 1
)

select
    sc.customer_id,
    sc.customer_name,
    sc.market_segment,
    coalesce(cm.total_orders, 0) as total_orders
from sat_customer sc
left join customer_metrics cm on sc.customer_id = cm.customer_id