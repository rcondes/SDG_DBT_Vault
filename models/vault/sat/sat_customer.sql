{{ config(materialized='incremental', unique_key='sat_hk') }}

with source_data as (
    select * from {{ ref('stg_customer') }}
),

-- 0. Preparamos los datos y calculamos los hashes que el STG no trae
staging as (
    select
        customer_id,
        customer_name,
        customer_address,
        customer_nation_id,
        customer_phone,
        account_balance,
        market_segment,
        customer_comment,
        load_timestamp as valid_from,
        
        -- Hash único por cada versión del cliente (PK del Satélite)
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'load_timestamp']) }} as sat_hk,

        -- Hash de diferencia para detectar si los datos del cliente han cambiado
        {{ dbt_utils.generate_surrogate_key([
            'customer_name', 
            'customer_address', 
            'customer_nation_id', 
            'customer_phone', 
            'account_balance', 
            'market_segment', 
            'customer_comment']) }} as hashdiff
    from 
        source_data
)

{% if not is_incremental() %}
-- CARGA INICIAL
select
    sat_hk,
    customer_id,
    customer_name,
    customer_address,
    customer_nation_id,
    customer_phone,
    account_balance,
    market_segment,
    customer_comment,
    valid_from,
    cast('9999-12-31 23:59:59' as timestamp) as valid_to,
    hashdiff
from 
    staging

{% else %}
-- CARGAS INCREMENTALES
, current_sat as (
    select *
    from {{ this }}
    where valid_to = cast('9999-12-31 23:59:59' as timestamp)
),

-- 2. Clientes NUEVOS
new_records as (
    select
        s.sat_hk,
        s.customer_id,
        s.customer_name,
        s.customer_address,
        s.customer_nation_id,
        s.customer_phone,
        s.account_balance,
        s.market_segment,
        s.customer_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    left join current_sat cs on s.customer_id = cs.customer_id
    where cs.customer_id is null
),

-- 3. Clientes existentes que TRAEN CAMBIOS: Insertamos la nueva versión vigente
changed_new_versions as (
    select
        s.sat_hk,
        s.customer_id,
        s.customer_name,
        s.customer_address,
        s.customer_nation_id,
        s.customer_phone,
        s.account_balance,
        s.market_segment,
        s.customer_comment,
        s.valid_from,
        cast('9999-12-31 23:59:59' as timestamp) as valid_to,
        s.hashdiff
    from staging s
    inner join current_sat cs on s.customer_id = cs.customer_id
    where s.hashdiff != cs.hashdiff
),

-- 4. Clientes existentes que TRAEN CAMBIOS: Cerramos la vigencia del registro antiguo
changed_old_versions as (
    select
        cs.sat_hk,
        cs.customer_id,
        cs.customer_name,
        cs.customer_address,
        cs.customer_nation_id,
        cs.customer_phone,
        cs.account_balance,
        cs.market_segment,
        cs.customer_comment,
        cs.valid_from,
        s.valid_from as valid_to, -- Su fin de vigencia es el inicio de la nueva versión
        cs.hashdiff
    from current_sat cs
    inner join staging s on cs.customer_id = s.customer_id
    where s.hashdiff != cs.hashdiff
),

-- 5. Unión de todos los flujos incrementales calculados en esta ventana
final as (
    select * from new_records
    union all
    select * from changed_new_versions
    union all
    select * from changed_old_versions
)

select * from final

{% endif %}