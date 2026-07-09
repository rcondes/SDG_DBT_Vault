-- models/vault/hubs/hub_part.sql
{{ config(materialized='incremental', unique_key='part_hk', tags=['hub']) }}

with stage_data as (
    select
        lower(md5(cast(part_id as varchar))) as part_hk,
        part_id,
        load_timestamp
    from {{ ref('stg_part') }}
    where part_id is not null
),

distinct_records as (
    select
        part_hk,
        part_id,
        max(load_timestamp) as load_timestamp
    from stage_data
    group by 1, 2
)

select * from distinct_records

{% if is_incremental() %}
where part_hk not in (select part_hk from {{ this }})
{% endif %}