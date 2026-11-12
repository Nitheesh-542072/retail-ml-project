{{ config(
    materialized = 'incremental',
    unique_key = ['po_id', 'sku_id']
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='assert_purchase_order_dates') %}

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
where err.po_id is null
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
{% else %}
{% if is_incremental() %}
where b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
{% endif %}
