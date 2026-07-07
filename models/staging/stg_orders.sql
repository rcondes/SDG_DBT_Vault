{{ config(materialized='view') }}

with source_data as (

    select * from {{ source('raw_source', 'raw_orders') }}

),

final as (

    select
        -- 1. Claves Naturales e Identificadores
        o_orderkey as order_id,
        o_custkey as customer_id,

        -- 2. Claves Hash de Data Vault 2.0 (Hubs correspondientes)
        lower(md5(coalesce(trim(cast(o_orderkey as varchar)), ''))) as order_hk,
        lower(md5(coalesce(trim(cast(o_custkey as varchar)), ''))) as customer_hk,

        -- 3. Hash de Diferencias (ORDERS_HASHDIFF)
        lower(md5(concat_ws('||',
            coalesce(trim(cast(o_orderstatus as varchar)), '^^'),
            coalesce(trim(cast(o_totalprice as varchar)), '^^'),
            coalesce(trim(cast(o_orderdate as varchar)), '^^'),
            coalesce(trim(cast(o_orderpriority as varchar)), '^^'),
            coalesce(trim(cast(o_clerk as varchar)), '^^'),
            coalesce(trim(cast(o_shippriority as varchar)), '^^'),
            coalesce(trim(cast(o_comment as varchar)), '^^')
        ))) as orders_hashdiff,

        -- 4. Atributos descriptivos renombrados
        o_orderstatus as order_status,
        o_totalprice as total_price,
        o_orderdate as order_date,
        o_orderpriority as order_priority,
        o_clerk as clerk,
        o_shippriority as ship_priority,
        o_comment as comment,

        -- 5. Campos de Auditoría
        current_timestamp() as load_date,
        'SNOWFLAKE.RAW.RAW_ORDERS' as record_source

    from source_data

)

select * from final