-- ==============================================================================
-- Singular Test: assert_inventory_snapshot_math.sql
-- Table: tbl_inventory_snapshots
-- Business Rule:
--   1. available_qty must exactly equal on_hand_qty - reserved_qty.
--   2. All inventory quantities (on_hand, reserved, available, in_transit) must be >= 0.
--   3. is_stockout flag must be TRUE if and only if available_qty == 0.
-- Returns: Rows with math inconsistencies or negative stock levels.
-- ==============================================================================

select
    snapshot_date,
    sku_id,
    location_id,
    on_hand_qty,
    reserved_qty,
    available_qty,
    is_stockout
from {{ ref('tbl_inventory_snapshots') }}
where available_qty != (on_hand_qty - reserved_qty)
   or on_hand_qty < 0
   or reserved_qty < 0
   or available_qty < 0
   or in_transit_qty < 0
   or (available_qty = 0 and is_stockout = false)
   or (available_qty > 0 and is_stockout = true)

