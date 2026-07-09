-- Falla si existen duplicados por (r_regionkey, r_version)
select
  r_regionkey,
  r_version,
  count(*) as cnt
from {{ source('raw_source', 'raw_region') }}
group by 1,2
having count(*) > 1