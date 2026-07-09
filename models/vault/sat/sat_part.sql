-- models/vault/sat/sat_part.sql
{{ config(materialized='incremental', unique_key='sat_part_key', tags=['sat']) }}

with src_raw as (
  select
    part_id,
    part_name,
    manufacturer,
    brand,
    part_type,
    part_size,
    container,
    retail_price,
    part_comment,
    load_timestamp,
    part_version
  from {{ ref('stg_part') }}
  where part_id is not null
),

src as (
  select
    lower(md5(cast(part_id as varchar))) as parent_hub_key,
    part_id,
    part_name,
    manufacturer,
    brand,
    part_type,
    part_size,
    container,
    retail_price,
    part_comment,
    load_timestamp as sat_load_dttm,
    part_version,
    lower(md5(concat_ws('||',
      coalesce(part_name,''),
      coalesce(manufacturer,''),
      coalesce(brand,''),
      coalesce(part_type,''),
      coalesce(part_size::varchar,''),
      coalesce(container,''),
      coalesce(retail_price::varchar,''),
      coalesce(part_comment,'')
    ))) as attribute_hash
  from (
    select
      *,
      row_number() over (
        partition by part_id
        order by part_version desc, load_timestamp desc
      ) as rn
    from src_raw
  ) t
  where rn = 1
)

{%- if is_incremental() %}

  {% set tmp_table = "tmp_dbt_sat_part_candidates_" ~ run_started_at.strftime('%s') %}

  {% set create_tmp %}
  create or replace temporary table {{ tmp_table }} as

  with src_raw as (
    select
      part_id,
      part_name,
      manufacturer,
      brand,
      part_type,
      part_size,
      container,
      retail_price,
      part_comment,
      load_timestamp,
      part_version
    from {{ ref('stg_part') }}
    where part_id is not null
  ),

  src as (
    select
      lower(md5(cast(part_id as varchar))) as parent_hub_key,
      part_id,
      part_name,
      manufacturer,
      brand,
      part_type,
      part_size,
      container,
      retail_price,
      part_comment,
      load_timestamp as sat_load_dttm,
      part_version,
      lower(md5(concat_ws('||',
        coalesce(part_name,''),
        coalesce(manufacturer,''),
        coalesce(brand,''),
        coalesce(part_type,''),
        coalesce(part_size::varchar,''),
        coalesce(container,''),
        coalesce(retail_price::varchar,''),
        coalesce(part_comment,'')
      ))) as attribute_hash
    from (
      select
        *,
        row_number() over (
          partition by part_id
          order by part_version desc, load_timestamp desc
        ) as rn
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
  {% do run_query(
    "update " ~ this ~ " target set effective_to = dateadd(second, -1, src.sat_load_dttm) from " ~ tmp_table ~ " src where target.parent_hub_key = src.parent_hub_key and target.effective_to = '9999-12-31'::timestamp"
  ) %}
  {% do run_query(
    "insert into " ~ this ~ " (sat_part_key,parent_hub_key,part_id,part_name,manufacturer,brand,part_type,part_size,container,retail_price,part_comment,attribute_hash,effective_from,effective_to,load_dttm,part_version) select uuid_string(), parent_hub_key,part_id,part_name,manufacturer,brand,part_type,part_size,container,retail_price,part_comment,attribute_hash,sat_load_dttm,'9999-12-31'::timestamp,sat_load_dttm,part_version from " ~ tmp_table
  ) %}
  {% do run_query("drop table if exists " ~ tmp_table) %}

  select
    sat_part_key,
    parent_hub_key,
    part_id,
    part_name,
    manufacturer,
    brand,
    part_type,
    part_size,
    container,
    retail_price,
    part_comment,
    attribute_hash,
    effective_from,
    effective_to,
    load_dttm,
    part_version
  from {{ this }}

{%- else %}

  select
    uuid_string() as sat_part_key,
    parent_hub_key,
    part_id,
    part_name,
    manufacturer,
    brand,
    part_type,
    part_size,
    container,
    retail_price,
    part_comment,
    attribute_hash,
    sat_load_dttm as effective_from,
    '9999-12-31'::timestamp as effective_to,
    sat_load_dttm as load_dttm,
    part_version
  from src

{%- endif %}