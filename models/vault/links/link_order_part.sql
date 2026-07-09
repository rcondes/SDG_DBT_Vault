{{ config(
    materialized='incremental',
    unique_key='link_key',
    tags=['link']
) }}

with src as (
  select
    -- Usamos la macro estándar para consistencia
    {{ dbt_utils.generate_surrogate_key(['order_id', 'line_number', 'part_id', 'li_version']) }} as link_key,
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as hub_order_key,
    {{ dbt_utils.generate_surrogate_key(['part_id']) }} as hub_part_key,
    order_id,
    line_number,
    part_id,
    load_timestamp as load_dttm
  from 
    {{ ref('stg_lineitem') }}
  where order_id is not null 
    and line_number is not null 
    and part_id is not null
)

select * from src

{% if is_incremental() %}
    -- Solo insertamos si el link_key no existe en la tabla actual
    where link_key not in (select link_key from {{ this }})
{% endif %}