select
    raw_payload:po_id::string as po_id,
    raw_payload:supplier_id::string as supplier_id,
    raw_payload:destination_location_id::string as destination_location_id,
    raw_payload:order_date::date as order_date,
    raw_payload:expected_delivery_date::date as expected_delivery_date,
    raw_payload:actual_delivery_date::date as actual_delivery_date,
    raw_payload:status::string as po_status,
    raw_payload:total_po_value::number(12, 2) as total_po_value,
    raw_payload:items as items_array,
    source_file_name,
    '{{ source("raw", "purchase_orders_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'purchase_orders_raw') }}

