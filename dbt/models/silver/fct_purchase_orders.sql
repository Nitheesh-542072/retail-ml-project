{{ config(
    materialized = 'incremental',
    unique_key = ['po_id', 'sku_id']
) }}

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
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
