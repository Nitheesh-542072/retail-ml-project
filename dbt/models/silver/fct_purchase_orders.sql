{{ config(
    materialized = 'incremental',
    unique_key = ['po_id', 'sku_id']
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_purchase_orders') %}

select
    b.po_id,
    b.sku_id,
    b.supplier_id,
    b.destination_location_id,
    b.ordered_qty,
    b.received_qty,
    b.order_date,
    b.expected_delivery_date,
    b.actual_delivery_date,
    b.status,
    b.unit_cost,
    b.total_po_value,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('purchase_orders') }} as b
{% if err_table %}
left join {{ err_table }} as err
    on b.po_id = err.po_id
   and b.sku_id = err.sku_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.po_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
