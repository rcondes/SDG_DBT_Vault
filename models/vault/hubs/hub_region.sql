-- models/vault/hubs/hub_region.sql
{{ config(materialized='incremental', unique_key='region_hk', tags=['hub']) }}

with stage_data as (
    select
        lower(md5(cast(region_id as varchar))) as region_hk,
        region_id,
        load_timestamp
    from {{ ref('stg_region') }}
    where region_id is not null
),

distinct_records as (
    select
        region_hk,
        region_id,
        max(load_timestamp) as load_timestamp
    from stage_data
    group by 1, 2
)

select * from distinct_records

{% if is_incremental() %}
where region_hk not in (select region_hk from {{ this }})
{% endif %}