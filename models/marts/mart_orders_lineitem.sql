{{ config(materialized='table', tags=['mart']) }}

with link_op as (
  select * from {{ ref('link_order_part') }}
),

stg_data as (
  -- Aquí traemos las métricas que NO están en el LINK
  select order_id, line_number, part_id, quantity, extended_price 
  from {{ ref('stg_lineitem') }}
),

orders_sat as (
  select * from {{ ref('sat_orders') }} where valid_to = '9999-12-31 23:59:59.000'
),

parts_sat as (
  select * from {{ ref('sat_part') }} where valid_to = '9999-12-31 23:59:59.000'
)

select
  l.link_key as order_line_key,
  l.order_id,
  l.part_id,
  l.line_number,
  s.quantity,
  s.extended_price,
  (s.quantity * s.extended_price) as line_total,
  os.order_status,
  p.part_name
from link_op l
join stg_data s on l.order_id = s.order_id and l.line_number = s.line_number
left join orders_sat os on l.hub_order_key = {{ dbt_utils.generate_surrogate_key(['os.order_id']) }}
left join parts_sat p on l.hub_part_key = {{ dbt_utils.generate_surrogate_key(['p.part_id']) }}