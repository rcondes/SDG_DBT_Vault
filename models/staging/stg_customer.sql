{{ config(materialized='view') }}

with source_data as (

    select * from {{ source('raw_source', 'raw_customer') }}

),

final as (

    select
        -- 1. Clave Natural
        c_custkey as customer_id,

        -- 2. Clave Hash del Hub (CUSTOMER_HK)
        lower(md5(coalesce(trim(cast(c_custkey as varchar)), ''))) as customer_hk,

        -- 3. Hash de Diferencias (CUSTOMER_HASHDIFF)
        lower(md5(concat_ws('||',
            coalesce(trim(cast(c_name as varchar)), '^^'),
            coalesce(trim(cast(c_address as varchar)), '^^'),
            coalesce(trim(cast(c_phone as varchar)), '^^'),
            coalesce(trim(cast(c_acctbal as varchar)), '^^'),
            coalesce(trim(cast(c_mktsegment as varchar)), '^^'),
            coalesce(trim(cast(c_comment as varchar)), '^^')
        ))) as customer_hashdiff,

        -- 4. Atributos descriptivos limpios
        c_name as name,
        c_address as address,
        c_nationkey as nation_id,
        c_phone as phone,
        c_acctbal as account_balance,
        c_mktsegment as market_segment,
        c_comment as comment,

        -- 5. Campos de Auditoría
        current_timestamp() as load_date,
        'SNOWFLAKE.RAW.RAW_CUSTOMER' as record_source

    from source_data

)

select * from final