{{ config(materialized='table') }}

with staging_data as (
    select supplier_hk, supplier_id, load_date, record_source 
    from {{ ref('stg_supplier') }}
),
final as (
    select 
        supplier_hk, 
        supplier_id, 
        load_date, 
        record_source
    from (
        select *, row_number() over (partition by supplier_hk order by load_date asc) as rn
        from staging_data
        where supplier_hk is not null
    )
    where rn = 1
)
select * from final