-- ==============================================================================
-- Singular Test: assert_transfer_locations_different.sql
-- Table: tbl_transfers
-- Business Rule:
--   1. An internal stock transfer must move between two distinct locations (from != to).
--   2. Transfer quantity must be strictly positive (> 0).
--   3. If received_date is recorded, it must be >= shipped_date.
-- Returns: Transfers with invalid origin/destination, negative quantities, or invalid dates.
-- ==============================================================================

select
    transfer_id,
    from_location_id,
    to_location_id,
    qty,
    shipped_date,
    received_date
from {{ ref('tbl_transfers') }}
where from_location_id = to_location_id
   or qty <= 0
   or (received_date is not null and received_date < shipped_date)

