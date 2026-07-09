-- Falla si existen duplicados por (o_orderkey, o_version)
select
  o_orderkey,
  o_version,
  count(*) as cnt
from {{ source('raw_source', 'raw_orders') }}
group by 1,2
having count(*) > 1