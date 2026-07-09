{{ config(materialized='incremental', unique_key='sat_key', tags=['sat']) }}

with src as (
  select
    lower(md5(cast(part_id as varchar))) as parent_hub_key,
    part_id,
    part_name,
    manufacturer,
    brand,
    part_type,
    part_size,
    retail_price,
    part_comment,
    load_timestamp as load_dttm,
    part_version,
    record_source,
    lower(md5(concat_ws('||', part_name, manufacturer, brand, part_type, part_size, retail_price, part_comment))) as attribute_hash
  from 
    {{ ref('stg_part') }}
  where 
    part_id is not null
),

last as (
  {%- if is_incremental() %}
    select parent_hub_key, attribute_hash as last_attribute_hash
    from (
      select parent_hub_key, attribute_hash,
             row_number() over (partition by parent_hub_key order by part_version desc, load_dttm desc) as rn
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
    lower(md5(concat(s.parent_hub_key, '||', cast(s.part_version as varchar), '||', s.attribute_hash))) as sat_key,
    s.parent_hub_key,
    s.part_id,
    s.part_name,
    s.manufacturer,
    s.brand,
    s.part_type,
    s.part_size,
    s.retail_price,
    s.part_comment,
    s.load_dttm,
    s.part_version,
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