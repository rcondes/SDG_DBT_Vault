-- Falla si existen duplicados por (l_orderkey, l_linenumber, l_version)
select
  l_orderkey,
  l_linenumber,
  l_version,
  count(*) as cnt
from {{ source('raw_source', 'raw_lineitem') }}
group by 1,2,3
having count(*) > 1