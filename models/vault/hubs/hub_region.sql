{{ config(materialized='table') }}

with staging_data as (
    select region_hk, region_id, load_date, record_source 
    from {{ ref('stg_region') }}
),
final as (
    select 
        region_hk, 
        region_id, 
        load_date, 
        record_source
    from (
        select *, row_number() over (partition by region_hk order by load_date desc) as rn
        from staging_data
        where region_hk is not null
    )
    where rn = 1
)
select * from final