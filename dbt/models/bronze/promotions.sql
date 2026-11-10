{{ config(
    materialized = 'incremental',
    unique_key = ['promo_id', 'sku_id']
) }}

select
    raw_payload:promo_id::string as promo_id,
    sku.value::string as sku_id,
    raw_payload:applicable_categories[0]::string as category,
    raw_payload:applicable_regions[0]::string as region,
    raw_payload:promo_type::string as promo_type,
    raw_payload:discount_pct::integer as discount_pct,
    raw_payload:start_date::date as start_date,
    raw_payload:end_date::date as end_date,
    raw_payload:status::string as promo_status,
    source_file_name,
    ingestion_timestamp
from
    {{ source('raw', 'promotions_raw') }},
    lateral flatten(input => raw_payload:applicable_skus) as sku

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
