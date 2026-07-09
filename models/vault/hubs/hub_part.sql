{{ config(materialized='table') }}

with staging_data as (
    select part_hk, part_id, load_date, record_source 
    from {{ ref('stg_part') }}
),
final as (
    select 
        part_hk, 
        part_id, 
        load_date, 
        record_source
    from (
        select *, row_number() over (partition by part_hk order by load_date desc) as rn
        from staging_data
        where part_hk is not null
    )
    where rn = 1
)
select * from final