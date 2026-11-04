-- ==============================================================================
-- Singular Test: assert_purchase_order_dates.sql
-- Table: tbl_purchase_orders
-- Business Rule:
--   1. expected_delivery_date must be greater than or equal to order_date.
--   2. If actual_delivery_date is recorded, it must be >= order_date.
--   3. total_po_value must be greater than 0.
-- Returns: Purchase orders violating chronological sequence or positive value.
-- ==============================================================================

select
    po_id,
    supplier_id,
    order_date,
    expected_delivery_date,
    actual_delivery_date,
    total_po_value
from {{ ref('tbl_purchase_orders') }}
where expected_delivery_date < order_date
   or (actual_delivery_date is not null and actual_delivery_date < order_date)
   or total_po_value <= 0

