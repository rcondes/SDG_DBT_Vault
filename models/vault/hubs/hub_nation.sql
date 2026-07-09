-- models/vault/hubs/hub_nation.sql
{{ config(materialized='incremental', unique_key='nation_hk', tags=['hub']) }}

with stage_data as (
    select
        lower(md5(cast(nation_id as varchar))) as nation_hk,
        nation_id,
        load_timestamp
    from {{ ref('stg_nation') }}
    where nation_id is not null
),

distinct_records as (
    select
        nation_hk,
        nation_id,
        -- si la misma nation aparece en varias versiones, quedarnos con la fecha de carga más reciente
        max(load_timestamp) as load_timestamp
    from stage_data
    group by 1, 2
)

select * from distinct_records

{% if is_incremental() %}
where nation_hk not in (select nation_hk from {{ this }})
{% endif %}