-- Falla si existen duplicados por (p_partkey, p_version)
select
  p_partkey,
  p_version,
  count(*) as cnt
from {{ source('raw_source', 'raw_part') }}
group by 1,2
having count(*) > 1