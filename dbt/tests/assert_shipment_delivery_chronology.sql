-- ==============================================================================
-- Singular Test: assert_shipment_delivery_chronology.sql
-- Table: shipments
-- Business Rule:
--   1. If delivered_timestamp is present, it must be >= ship_timestamp.
--   2. shipping_cost must be non-negative (>= 0).
-- Returns: Shipments with backwards delivery timestamps or negative freight costs.
-- ==============================================================================

select
    shipment_id,
    order_id,
    ship_timestamp,
    delivered_timestamp,
    shipping_cost
from {{ ref('shipments') }}
where (delivered_timestamp is not null and delivered_timestamp < ship_timestamp)
   or shipping_cost < 0

