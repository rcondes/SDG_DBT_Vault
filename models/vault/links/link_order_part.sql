{{ config(materialized='incremental', unique_key='link_key', tags=['link']) }}

with src as (
  select
    lower(md5(cast(concat(order_id,'||',line_number,'||',part_id) as varchar))) as link_key,
    lower(md5(cast(order_id as varchar))) as hub_order_key,
    lower(md5(cast(part_id as varchar))) as hub_part_key,
    order_id,
    line_number,
    part_id,
    load_timestamp as load_dttm
  from 
    {{ ref('stg_lineitem') }}
  where order_id is not null and line_number is not null and part_id is not null
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