select
    raw_payload:po_id::string as po_id,
    raw_payload:supplier_id::string as supplier_id,
    raw_payload:destination_location_id::string as destination_location_id,
    item.value:sku_id::string as sku_id,
    item.value:ordered_qty::integer as ordered_qty,
    item.value:received_qty::integer as received_qty,
    raw_payload:order_date::date as order_date,
    raw_payload:expected_delivery_date::date as expected_delivery_date,
    raw_payload:actual_delivery_date::date as actual_delivery_date,
    raw_payload:status::string as status,
    item.value:unit_cost::number(10, 2) as unit_cost,
    source_file_name,
    '{{ source("raw", "purchase_orders_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'purchase_orders_raw') }},
    lateral flatten(input => raw_payload:items) as item
