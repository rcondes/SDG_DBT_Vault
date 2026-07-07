-- Validar formato YYYY-MM-DD para cualquier columna de fecha
select 
    order_id, 
    order_date
from {{ ref('stg_orders') }}
where CAST(order_date AS VARCHAR) IS NOT NULL 
  and CAST(order_date AS VARCHAR) != ''
  and not regexp_like(CAST(order_date AS VARCHAR), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')