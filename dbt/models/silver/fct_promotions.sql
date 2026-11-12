{{ config(
    materialized = 'incremental',
    unique_key = ['promo_id', 'sku_id']
) }}

select
    promo_id,
    sku_id,
    category,
    region,
    promo_type,
    discount_pct,
    start_date,
    end_date,
    promo_status,
    source_file_name,
    ingestion_timestamp
from {{ ref('promotions') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
