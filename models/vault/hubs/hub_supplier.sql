-- models/vault/hubs/hub_supplier.sql
{{ config(materialized='incremental', unique_key='supplier_hk', tags=['hub']) }}

with stage_data as (
    select
        lower(md5(cast(supplier_id as varchar))) as supplier_hk,
        supplier_id,
        load_timestamp
    from {{ ref('stg_supplier') }}
    where supplier_id is not null
),

distinct_records as (
    select
        supplier_hk,
        supplier_id,
        max(load_timestamp) as load_timestamp
    from stage_data
    group by 1, 2
)

select * from distinct_records

{% if is_incremental() %}
where supplier_hk not in (select supplier_hk from {{ this }})
{% endif %}