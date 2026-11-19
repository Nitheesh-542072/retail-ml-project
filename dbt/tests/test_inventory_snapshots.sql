-- Consolidated validation test for inventory_snapshots
-- Covers: composite PK nulls, duplicates, math checks, negative quantities, stockout flag, foreign keys

with duplicates as (
    select snapshot_date, sku_id, location_id
    from {{ ref('inventory_snapshots') }}
    where snapshot_date is not null and sku_id is not null and location_id is not null
    group by snapshot_date, sku_id, location_id
    having count(*) > 1
),
valid_products as (
    select sku_id from {{ ref('products') }} where sku_id is not null
),
valid_locations as (
    select location_id from {{ ref('locations') }} where location_id is not null
)

select
    s.snapshot_date,
    s.sku_id,
    s.location_id,
    s.on_hand_qty,
    s.reserved_qty,
    s.available_qty,
    s.is_stockout,
    case
        when s.snapshot_date is null or s.sku_id is null or s.location_id is null then 'Missing composite primary key components'
        when d.sku_id is not null then 'Duplicate snapshot composite key'
        when s.available_qty != (s.on_hand_qty - s.reserved_qty) then 'Math violation: available_qty != (on_hand - reserved)'
        when s.on_hand_qty < 0 or s.reserved_qty < 0 or s.available_qty < 0 or s.in_transit_qty < 0 then 'Negative stock balance quantity'
        when s.available_qty = 0 and s.is_stockout = false then 'Stockout flag mismatch: available_qty == 0 but is_stockout is false'
        when s.available_qty > 0 and s.is_stockout = true then 'Stockout flag mismatch: available_qty > 0 but is_stockout is true'
        when vp.sku_id is null then 'Foreign key violation: sku_id does not exist in products'
        when vl.location_id is null then 'Foreign key violation: location_id does not exist in locations'
        else 'Inventory snapshot validation failure'
    end as failure_reason
from {{ ref('inventory_snapshots') }} as s
left join duplicates as d
    on s.snapshot_date = d.snapshot_date and s.sku_id = d.sku_id and s.location_id = d.location_id
left join valid_products as vp
    on s.sku_id = vp.sku_id
left join valid_locations as vl
    on s.location_id = vl.location_id
where s.snapshot_date is null
   or s.sku_id is null
   or s.location_id is null
   or d.sku_id is not null
   or s.available_qty != (s.on_hand_qty - s.reserved_qty)
   or s.on_hand_qty < 0
   or s.reserved_qty < 0
   or s.available_qty < 0
   or s.in_transit_qty < 0
   or (s.available_qty = 0 and s.is_stockout = false)
   or (s.available_qty > 0 and s.is_stockout = true)
   or vp.sku_id is null
   or vl.location_id is null
