-- Falla si existen duplicados por (s_suppkey, s_version)
select
  s_suppkey,
  s_version,
  count(*) as cnt
from {{ source('raw_source', 'raw_supplier') }}
group by 1,2
having count(*) > 1