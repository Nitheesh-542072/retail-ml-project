{{ config(
    materialized = 'incremental',
    unique_key = 'sku_id'
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='TEST_PRODUCTS') %}
{% if not err_table %}
  {% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_products') %}
{% endif %}

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
{% if err_table %}
left join {{ err_table }} as err
    on b.sku_id = err.sku_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.sku_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
