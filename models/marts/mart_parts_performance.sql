{{ config(materialized='table', tags=['mart']) }}

with usage_metrics as (
    select 
        part_id, 
        sum(quantity) as total_quantity_ordered, 
        sum(line_total) as total_revenue
    from {{ ref('mart_orders_lineitem') }}
    group by 1
),
sat_part as (
    select * from {{ ref('sat_part') }} where valid_to = '9999-12-31 23:59:59.000'
)

select
    p.part_id,
    p.part_name,
    p.brand,
    coalesce(u.total_quantity_ordered, 0) as total_quantity_ordered,
    coalesce(u.total_revenue, 0) as total_revenue
from sat_part p
left join usage_metrics u on p.part_id = u.part_id