{{ config(
    materialized = 'incremental',
    unique_key = 'sku_id'
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='assert_product_pricing_logic') %}

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
where err.sku_id is null
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
{% else %}
{% if is_incremental() %}
where b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
{% endif %}
