select
    snapshot_date::date as snapshot_date,
    sku_id::string as sku_id,
    location_id::string as location_id,
    on_hand_qty::integer as on_hand_qty,
    reserved_qty::integer as reserved_qty,
    available_qty::integer as available_qty,
    in_transit_qty::integer as in_transit_qty,
    damaged_qty::integer as damaged_qty,
    safety_stock_qty::integer as safety_stock_qty,
    is_stockout::boolean as is_stockout,
    source_file_name,
    '{{ source("raw", "inventory_snapshots_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'inventory_snapshots_raw') }}

