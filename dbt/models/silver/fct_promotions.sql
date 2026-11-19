{{ config(
    materialized = 'incremental',
    unique_key = ['promo_id', 'sku_id']
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_promotions') %}

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
{% if err_table %}
left join {{ err_table }} as err
    on b.promo_id = err.promo_id
   and b.sku_id = err.sku_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.promo_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
