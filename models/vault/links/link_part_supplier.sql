{{ config(
    materialized='incremental',
    unique_key='link_key',
    tags=['link']
) }}

with src as (
  select
    -- Hash del LINK generado con la macro estándar
    {{ dbt_utils.generate_surrogate_key(['part_id', 'supplier_id', 'ps_version']) }} as link_key,
    
    -- Hashes de los HUBs (deben coincidir con la lógica usada en los modelos de HUB)
    {{ dbt_utils.generate_surrogate_key(['part_id']) }} as hub_part_key,
    {{ dbt_utils.generate_surrogate_key(['supplier_id']) }} as hub_supplier_key,
    
    part_id,
    supplier_id,
    load_timestamp as load_dttm
  from 
    {{ ref('stg_partsupp') }}
  where 
    part_id is not null 
    and supplier_id is not null
)

select * from src

{% if is_incremental() %}
    -- Solo insertamos registros nuevos que no estén ya en la tabla final
    where link_key not in (select link_key from {{ this }})
{% endif %}