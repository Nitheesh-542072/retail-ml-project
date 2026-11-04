select
    movement_id::string as movement_id,
    sku_id::string as sku_id,
    location_id::string as location_id,
    movement_type::string as movement_type,
    quantity::integer as quantity,
    reference_id::string as reference_id,
    nullif(reason_code, '')::string as reason_code,
    timestamp::timestamp_ntz as movement_timestamp,
    source_file_name,
    '{{ source("raw", "inventory_movements_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'inventory_movements_raw') }}

