{{ config(
    materialized = 'incremental',
    unique_key = 'sku_id'
) }}

select
    b.sku_id,
    b.product_name,
    b.category,
    b.brand,
    b.abc_class,
    b.unit_cost,
    b.unit_price,
    b.case_pack_qty,
    b.weight_kg,
    b.shelf_life_days,
    b.status,
    b.launch_date,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('products') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
