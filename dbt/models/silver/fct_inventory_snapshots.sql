{{ config(
    materialized = 'incremental',
    unique_key = ['snapshot_date', 'sku_id', 'location_id']
) }}

select
    b.snapshot_date,
    b.sku_id,
    b.location_id,
    b.on_hand_qty,
    b.reserved_qty,
    b.available_qty,
    b.in_transit_qty,
    b.damaged_qty,
    b.safety_stock_qty,
    b.is_stockout,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('inventory_snapshots') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
