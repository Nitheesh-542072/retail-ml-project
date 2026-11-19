-- Consolidated validation test for inventory_movements
-- Covers: null PK, duplicates, movement types, quantity validation, timestamp, foreign keys to products and locations

with duplicates as (
    select movement_id
    from {{ ref('inventory_movements') }}
    where movement_id is not null
    group by movement_id
    having count(*) > 1
),
valid_products as (
    select sku_id from {{ ref('products') }} where sku_id is not null
),
valid_locations as (
    select location_id from {{ ref('locations') }} where location_id is not null
)

select
    m.movement_id,
    m.sku_id,
    m.location_id,
    m.movement_type,
    m.quantity,
    m.movement_timestamp,
    case
        when m.movement_id is null then 'Missing primary key movement_id'
        when d.movement_id is not null then 'Duplicate movement_id'
        when m.sku_id is null then 'Missing sku_id'
        when m.location_id is null then 'Missing location_id'
        when m.movement_type not in ('RECEIPT', 'SALE', 'TRANSFER_IN', 'TRANSFER_OUT', 'RETURN', 'ADJUSTMENT', 'WRITE_OFF') then 'Invalid movement_type'
        when m.quantity is null or m.quantity = 0 then 'Invalid movement quantity (null or zero)'
        when m.movement_timestamp is null then 'Missing movement_timestamp'
        when vp.sku_id is null then 'Foreign key violation: sku_id does not exist in products'
        when vl.location_id is null then 'Foreign key violation: location_id does not exist in locations'
        else 'Inventory movement validation failure'
    end as failure_reason
from {{ ref('inventory_movements') }} as m
left join duplicates as d
    on m.movement_id = d.movement_id
left join valid_products as vp
    on m.sku_id = vp.sku_id
left join valid_locations as vl
    on m.location_id = vl.location_id
where m.movement_id is null
   or d.movement_id is not null
   or m.sku_id is null
   or m.location_id is null
   or m.movement_type not in ('RECEIPT', 'SALE', 'TRANSFER_IN', 'TRANSFER_OUT', 'RETURN', 'ADJUSTMENT', 'WRITE_OFF')
   or m.quantity is null
   or m.quantity = 0
   or m.movement_timestamp is null
   or vp.sku_id is null
   or vl.location_id is null
