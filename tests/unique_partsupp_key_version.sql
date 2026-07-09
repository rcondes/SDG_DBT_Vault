-- Falla si existen duplicados por (ps_partkey, ps_suppkey, ps_version)
select
  ps_partkey,
  ps_suppkey,
  ps_version,
  count(*) as cnt
from {{ source('raw_source', 'raw_partsupp') }}
group by 1,2,3
having count(*) > 1