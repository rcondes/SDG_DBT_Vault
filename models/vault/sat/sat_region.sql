{{ config(materialized='incremental', unique_key='sat_key', tags=['sat']) }}

with src as (
  select
    lower(md5(cast(region_id as varchar))) as parent_hub_key,
    region_id,
    region_name,
    load_timestamp as load_dttm,
    region_version,
    record_source,
    lower(md5(concat_ws('||', region_name))) as attribute_hash
  from 
    {{ ref('stg_region') }}
  where
    region_id is not null
),

last as (
  {%- if is_incremental() %}
    select parent_hub_key, attribute_hash as last_attribute_hash
    from (
      select parent_hub_key, attribute_hash,
             row_number() over (partition by parent_hub_key order by region_version desc, load_dttm desc) as rn
      from {{ this }}
    ) t
    where rn = 1
  {%- else %}
    -- primera ejecución: no existe tabla objetivo, devolvemos conjunto vacío
    select null::varchar as parent_hub_key, null::varchar as last_attribute_hash
    where false
  {% endif -%}
),

to_insert as (
  select
    lower(md5(concat(s.parent_hub_key, '||', cast(s.region_version as varchar), '||', s.attribute_hash))) as sat_key,
    s.parent_hub_key,
    s.region_id,
    s.region_name,
    s.load_dttm,
    s.region_version,
    s.attribute_hash,
    s.record_source
  from src s
  left join last l
    on s.parent_hub_key = l.parent_hub_key
  where
    l.parent_hub_key is null
    or s.attribute_hash != l.last_attribute_hash
)

select * from to_insert