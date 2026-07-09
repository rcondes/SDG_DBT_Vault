{{ config(materialized='incremental', unique_key='business_key', tags=['hub']) }}

with src as (
  select
    lower(md5(cast(region_id as varchar))) as hub_key,
    region_id as business_key,
    load_timestamp as first_seen_dttm,
    'raw_region' as record_source
  from 
    {{ ref('stg_region') }}
  where 
    region_id is not null
),

existing as (
    {%- if is_incremental() %}
        select region_id business_key from {{ this }}
    {%- else %}
        -- primera ejecución: tabla objetivo no existe aún, devolvemos conjunto vacío
        select null::varchar as business_key where false
    {% endif -%}
),

to_insert as (
  select s.*
  from src s
  left join existing h
    on s.business_key = h.business_key
  where h.business_key is null
)

select * from to_insert