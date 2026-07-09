{{ config(materialized='incremental', unique_key='sat_key', tags=['sat']) }}

with src as (
  select
    lower(md5(cast(customer_id as varchar))) as parent_hub_key,
    customer_id,
    customer_name,
    customer_address,
    customer_nation_id,
    customer_phone,
    account_balance,
    market_segment,
    customer_comment,
    coalesce(load_timestamp, current_timestamp()) as load_dttm,
    customer_version,
    record_source,
    lower(md5(concat_ws('||', customer_name, customer_address, customer_nation_id, customer_phone, account_balance, market_segment, customer_comment))) as attribute_hash
  from 
    {{ ref('stg_customer') }}
  where 
    customer_id is not null
),

last as (
  {%- if is_incremental() %}
    select parent_hub_key, attribute_hash as last_attribute_hash
    from (
      select parent_hub_key, attribute_hash,
             row_number() over (partition by parent_hub_key order by customer_version desc, load_dttm desc) as rn
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
    lower(md5(concat(s.parent_hub_key, '||', cast(s.customer_version as varchar), '||', s.attribute_hash))) as sat_key,
    s.parent_hub_key,
    s.customer_id,
    s.customer_name,
    s.customer_address,
    s.customer_nation_id,
    s.customer_phone,
    s.account_balance,
    s.market_segment,
    s.customer_comment,
    s.load_dttm,
    s.customer_version,
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