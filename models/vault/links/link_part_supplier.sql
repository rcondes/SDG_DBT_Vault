{{ config(materialized='incremental', unique_key='link_key', tags=['link']) }}

with src as (
  select
    lower(md5(cast(concat(part_id,'||',supplier_id) as varchar))) as link_key,
    lower(md5(cast(part_id as varchar))) as hub_part_key,
    lower(md5(cast(supplier_id as varchar))) as hub_supplier_key,
    part_id,
    supplier_id,
    load_timestamp as load_dttm,
    'raw_partsupp' as record_source
  from 
    {{ ref('stg_partsupp') }}
  where 
    part_id is not null and supplier_id is not null
),

existing as (
    {% if is_incremental() %}
        select link_key from {{ this }}
    {% else %}
        -- primera ejecución: tabla objetivo no existe aún, devolvemos conjunto vacío
        select null::varchar as link_key where false
    {% endif %}
),

to_insert as (
  select s.*
  from src s
  left join existing l
    on s.link_key = l.link_key
  where l.link_key is null
)

select * from to_insert