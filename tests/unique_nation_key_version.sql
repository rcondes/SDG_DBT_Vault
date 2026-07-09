-- Falla si existen duplicados por (n_nationkey, n_version)
select
  n_nationkey,
  n_version,
  count(*) as cnt
from {{ source('raw_source', 'raw_nation') }}
group by 1,2
having count(*) > 1