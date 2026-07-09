{{ config(materialized='incremental', unique_key='sat_customer_key', tags=['sat']) }}

with src_raw as (
  select
    customer_id,
    customer_name,
    customer_address,
    customer_nation_id,
    customer_phone,
    account_balance,
    market_segment,
    customer_comment,
    load_timestamp,
    customer_version
  from {{ ref('stg_customer') }}
  where customer_id is not null
),

src as (
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
    load_timestamp as sat_load_dttm,
    customer_version,
    lower(md5(
      concat_ws('||',
        coalesce(customer_name,''),
        coalesce(customer_address,''),
        coalesce(customer_nation_id::varchar,''),
        coalesce(customer_phone,''),
        coalesce(account_balance::varchar,''),
        coalesce(market_segment,''),
        coalesce(customer_comment,'')
      )
    )) as attribute_hash
  from (
    select
      *,
      row_number() over (partition by customer_id order by customer_version desc, load_timestamp desc) as rn
    from src_raw
  ) t
  where rn = 1
)

{%- if is_incremental() %}

  {% set tmp_table = "tmp_dbt_sat_customer_candidates_" ~ run_started_at.strftime('%s') %}

  {# 1) Crear temp table con la definición completa de src y la lógica de candidates #}
  {% set create_tmp %}
  create or replace temporary table {{ tmp_table }} as

  with src_raw as (
    select
      customer_id,
      customer_name,
      customer_address,
      customer_nation_id,
      customer_phone,
      account_balance,
      market_segment,
      customer_comment,
      load_timestamp,
      customer_version
    from {{ ref('stg_customer') }}
    where customer_id is not null
  ),

  src as (
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
      load_timestamp as sat_load_dttm,
      customer_version,
      lower(md5(
        concat_ws('||',
          coalesce(customer_name,''),
          coalesce(customer_address,''),
          coalesce(customer_nation_id::varchar,''),
          coalesce(customer_phone,''),
          coalesce(account_balance::varchar,''),
          coalesce(market_segment,''),
          coalesce(customer_comment,'')
        )
      )) as attribute_hash
    from (
      select
        *,
        row_number() over (partition by customer_id order by customer_version desc, load_timestamp desc) as rn
      from src_raw
    ) t
    where rn = 1
  )

  select
    s.*
  from src s
  left join {{ this }} t
    on t.parent_hub_key = s.parent_hub_key
    and t.effective_to = '9999-12-31'::timestamp
  where t.parent_hub_key is null
     or t.attribute_hash <> s.attribute_hash
  {% endset %}

  {% do run_query(create_tmp) %}

  {# 2) End-date la fila abierta previa (si existe) #}
  {% set update_open %}
  update {{ this }} target
  set effective_to = dateadd(second, -1, src.sat_load_dttm)
  from {{ tmp_table }} src
  where target.parent_hub_key = src.parent_hub_key
    and target.effective_to = '9999-12-31'::timestamp
  {% endset %}

  {% do run_query(update_open) %}

  {# 3) Insertar nuevas versiones #}
  {% set insert_new %}
  insert into {{ this }} (
    sat_customer_key,
    parent_hub_key,
    customer_id,
    customer_name,
    customer_address,
    customer_nation_id,
    customer_phone,
    account_balance,
    market_segment,
    customer_comment,
    attribute_hash,
    effective_from,
    effective_to,
    load_dttm,
    customer_version
  )
  select
    uuid_string() as sat_customer_key,
    parent_hub_key,
    customer_id,
    customer_name,
    customer_address,
    customer_nation_id,
    customer_phone,
    account_balance,
    market_segment,
    customer_comment,
    attribute_hash,
    sat_load_dttm as effective_from,
    '9999-12-31'::timestamp as effective_to,
    sat_load_dttm as load_dttm,
    customer_version
  from {{ tmp_table }}
  {% endset %}

  {% do run_query(insert_new) %}

  {# 4) Limpiar temp table #}
  {% do run_query("drop table if exists " ~ tmp_table) %}

  {# 5) Devolver filas para que dbt materialice la tabla #}
  select
    sat_customer_key,
    parent_hub_key,
    customer_id,
    customer_name,
    customer_address,
    customer_nation_id,
    customer_phone,
    account_balance,
    market_segment,
    customer_comment,
    attribute_hash,
    effective_from,
    effective_to,
    load_dttm,
    customer_version
  from {{ this }}

{%- else %}

  {# Full-refresh: crear la tabla con la versión más reciente por business key #}
  select
    uuid_string() as sat_customer_key,
    parent_hub_key,
    customer_id,
    customer_name,
    customer_address,
    customer_nation_id,
    customer_phone,
    account_balance,
    market_segment,
    customer_comment,
    attribute_hash,
    sat_load_dttm as effective_from,
    '9999-12-31'::timestamp as effective_to,
    sat_load_dttm as load_dttm,
    customer_version
  from src

{%- endif %}