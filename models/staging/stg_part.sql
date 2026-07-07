{{ config(materialized='view') }}
with source_data as (select * from {{ source('raw_source', 'raw_part') }}),
final as (
    select
        lower(md5(cast(trim(p_partkey) as varchar(100)))) as part_hk,
        p_partkey as part_id,
        p_name as name,
        p_mfgr as manufacturer,
        p_brand as brand,
        p_type as type,
        p_size as size,
        p_container as container,
        p_retailprice as retail_price,
        p_comment as comment,
        current_timestamp() as load_date,
        'RAW_PART' as record_source
    from source_data
)
select * from final