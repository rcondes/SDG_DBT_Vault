{{ config(materialized='table') }}

with staging_data as (
    select nation_hk, nation_id, load_date, record_source 
    from {{ ref('stg_nation') }}
),
final as (
    select 
        nation_hk, 
        nation_id, 
        load_date, 
        record_source
    from (
        select *, row_number() over (partition by nation_hk order by load_date desc) as rn
        from staging_data
        where nation_hk is not null
    )
    where rn = 1
)
select * from final