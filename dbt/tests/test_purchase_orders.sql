-- Consolidated validation test for purchase_orders
-- Covers: composite PK nulls, duplicates, positive quantities and values, delivery date sequence, status, foreign keys

with duplicates as (
    select po_id, sku_id
    from {{ ref('purchase_orders') }}
    where po_id is not null and sku_id is not null
    group by po_id, sku_id
    having count(*) > 1
),
valid_locations as (
    select location_id from {{ ref('locations') }} where location_id is not null
),
valid_products as (
    select sku_id from {{ ref('products') }} where sku_id is not null
),
valid_suppliers as (
    select distinct supplier_id from {{ ref('suppliers') }} where supplier_id is not null
)

select
    po.po_id,
    po.sku_id,
    po.supplier_id,
    po.destination_location_id,
    po.ordered_qty,
    po.received_qty,
    po.order_date,
    po.expected_delivery_date,
    po.actual_delivery_date,
    po.status,
    po.total_po_value,
    case
        when po.po_id is null or po.sku_id is null then 'Missing composite primary key components'
        when d.sku_id is not null then 'Duplicate po_id and sku_id'
        when po.supplier_id is null then 'Missing supplier_id'
        when po.destination_location_id is null then 'Missing destination_location_id'
        when po.ordered_qty is null or po.ordered_qty <= 0 then 'Invalid ordered_qty (must be > 0)'
        when po.received_qty < 0 then 'Negative received_qty'
        when po.unit_cost is null or po.unit_cost <= 0 then 'Invalid unit_cost (must be > 0)'
        when po.total_po_value is null or po.total_po_value <= 0 then 'total_po_value must be greater than 0'
        when po.order_date is null then 'Missing order_date'
        when po.expected_delivery_date < po.order_date then 'expected_delivery_date cannot precede order_date'
        when po.actual_delivery_date is not null and po.actual_delivery_date < po.order_date then 'actual_delivery_date cannot precede order_date'
        when po.status not in ('RECEIVED', 'OPEN', 'PARTIAL', 'CANCELLED') then 'Invalid purchase order status'
        when vl.location_id is null then 'Foreign key violation: destination_location_id does not exist in locations'
        when vp.sku_id is null then 'Foreign key violation: sku_id does not exist in products'
        when vs.supplier_id is null then 'Foreign key violation: supplier_id does not exist in suppliers'
        else 'Purchase order validation failure'
    end as failure_reason
from {{ ref('purchase_orders') }} as po
left join duplicates as d
    on po.po_id = d.po_id and po.sku_id = d.sku_id
left join valid_locations as vl
    on po.destination_location_id = vl.location_id
left join valid_products as vp
    on po.sku_id = vp.sku_id
left join valid_suppliers as vs
    on po.supplier_id = vs.supplier_id
where po.po_id is null
   or po.sku_id is null
   or d.sku_id is not null
   or po.supplier_id is null
   or po.destination_location_id is null
   or po.ordered_qty is null
   or po.ordered_qty <= 0
   or po.received_qty < 0
   or po.unit_cost is null
   or po.unit_cost <= 0
   or po.total_po_value is null
   or po.total_po_value <= 0
   or po.order_date is null
   or po.expected_delivery_date < po.order_date
   or (po.actual_delivery_date is not null and po.actual_delivery_date < po.order_date)
   or po.status not in ('RECEIVED', 'OPEN', 'PARTIAL', 'CANCELLED')
   or vl.location_id is null
   or vp.sku_id is null
   or vs.supplier_id is null
