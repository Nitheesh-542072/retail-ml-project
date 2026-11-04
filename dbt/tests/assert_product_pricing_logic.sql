-- ==============================================================================
-- Singular Test: assert_product_pricing_logic.sql
-- Table: tbl_products
-- Business Rule: 
--   1. Selling price (unit_price) must be strictly greater than wholesale cost (unit_cost).
--   2. Both unit_cost and unit_price must be positive numbers (> 0).
-- Returns: Rows violating positive margin or positive pricing rules.
-- ==============================================================================

select
    sku_id,
    product_name,
    unit_cost,
    unit_price,
    (unit_price - unit_cost) as profit_margin
from {{ ref('tbl_products') }}
where unit_price <= unit_cost
   or unit_cost <= 0
   or unit_price <= 0

