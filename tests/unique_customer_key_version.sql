-- Falla si existen duplicados por (c_custkey, c_version)
select
  c_custkey,
  c_version,
  count(*) as cnt
from {{ source('raw_source', 'raw_customer') }}
group by 1,2
having count(*) > 1