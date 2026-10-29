select
    raw_payload:inventory_id::string as inventory_id,
    raw_payload:product_id::string as product_id,
    raw_payload:location_id::string as location_id,
    raw_payload:location_type::string as location_type,
    raw_payload:quantity.available_quantity::integer as available_quantity,
    raw_payload:quantity.reserved_quantity::integer as reserved_quantity,
    raw_payload:quantity.reorder_threshold::integer as reorder_threshold,
    raw_payload:inventory_status::string as inventory_status,
    raw_payload:metrics.days_of_supply::number(10, 2) as days_of_supply,
    raw_payload:timestamp::timestamp_ntz as sync_timestamp,
    source_file_name,
    '{{ source("raw", "inventory_levels_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'inventory_levels_raw') }}

