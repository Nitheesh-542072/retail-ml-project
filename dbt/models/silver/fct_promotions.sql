{{ config(
    materialized = 'incremental',
    unique_key = ['promo_id', 'sku_id']
) }}

select
    b.promo_id,
    b.sku_id,
    b.category,
    b.region,
    b.promo_type,
    b.discount_pct,
    b.start_date,
    b.end_date,
    b.promo_status,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('promotions') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
