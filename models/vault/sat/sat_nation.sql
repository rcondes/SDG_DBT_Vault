-- models/vault/sat/sat_nation.sql
{{ config(materialized='incremental', unique_key='sat_nation_key', tags=['sat']) }}

with src_raw as (
  select
    nation_id,
    nation_name,
    region_id,
    comment,
    load_timestamp,
    nation_version
  from {{ ref('stg_nation') }}
  where nation_id is not null
),

src as (
  select
    lower(md5(cast(nation_id as varchar))) as parent_hub_key,
    nation_id,
    nation_name,
    region_id,
    comment,
    load_timestamp as sat_load_dttm,
    nation_version,
    lower(md5(concat_ws('||',
      coalesce(nation_name,''),
      coalesce(region_id::varchar,''),
      coalesce(comment,'')
    ))) as attribute_hash
  from (
    select
      *,
      row_number() over (partition by nation_id order by nation_version desc, load_timestamp desc) as rn
    from src_raw
  ) t
  where rn = 1
)

{%- if is_incremental() %}

  {% set tmp_table = "tmp_dbt_sat_nation_candidates_" ~ run_started_at.strftime('%s') %}

  {% set create_tmp %}
  create or replace temporary table {{ tmp_table }} as

  with src_raw as (
    select
      nation_id,
      nation_name,
      region_id,
      comment,
      load_timestamp,
      nation_version
    from {{ ref('stg_nation') }}
    where nation_id is not null
  ),

  src as (
    select
      lower(md5(cast(nation_id as varchar))) as parent_hub_key,
      nation_id,
      nation_name,
      region_id,
      comment,
      load_timestamp as sat_load_dttm,
      nation_version,
      lower(md5(concat_ws('||',
        coalesce(nation_name,''),
        coalesce(region_id::varchar,''),
        coalesce(comment,'')
      ))) as attribute_hash
    from (
      select
        *,
        row_number() over (partition by nation_id order by nation_version desc, load_timestamp desc) as rn
      from src_raw
    ) t
    where rn = 1
  )

  select s.*
  from src s
  left join {{ this }} t
    on t.parent_hub_key = s.parent_hub_key
    and t.effective_to = '9999-12-31'::timestamp
  where t.parent_hub_key is null
     or t.attribute_hash <> s.attribute_hash
  {% endset %}

  {% do run_query(create_tmp) %}

  {% set update_open %}
  update {{ this }} target
  set effective_to = dateadd(second, -1, src.sat_load_dttm)
  from {{ tmp_table }} src
  where target.parent_hub_key = src.parent_hub_key
    and target.effective_to = '9999-12-31'::timestamp
  {% endset %}

  {% do run_query(update_open) %}

  {% set insert_new %}
  insert into {{ this }} (
    sat_nation_key,
    parent_hub_key,
    nation_id,
    nation_name,
    region_id,
    comment,
    attribute_hash,
    effective_from,
    effective_to,
    load_dttm,
    nation_version
  )
  select
    uuid_string(),
    parent_hub_key,
    nation_id,
    nation_name,
    region_id,
    comment,
    attribute_hash,
    sat_load_dttm,
    '9999-12-31'::timestamp,
    sat_load_dttm,
    nation_version
  from {{ tmp_table }}
  {% endset %}

  {% do run_query(insert_new) %}
  {% do run_query("drop table if exists " ~ tmp_table) %}

  select
    sat_nation_key,
    parent_hub_key,
    nation_id,
    nation_name,
    region_id,
    comment,
    attribute_hash,
    effective_from,
    effective_to,
    load_dttm,
    nation_version
  from {{ this }}

{%- else %}

  select
    uuid_string() as sat_nation_key,
    parent_hub_key,
    nation_id,
    nation_name,
    region_id,
    comment,
    attribute_hash,
    sat_load_dttm as effective_from,
    '9999-12-31'::timestamp as effective_to,
    sat_load_dttm as load_dttm,
    nation_version
  from src

{%- endif %}