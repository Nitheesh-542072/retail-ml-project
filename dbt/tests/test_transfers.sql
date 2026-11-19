-- Consolidated validation test for transfers
-- Covers: null PK, duplicates, origin != destination, positive qty, date chronology, status, foreign keys

with duplicates as (
    select transfer_id
    from {{ ref('transfers') }}
    where transfer_id is not null
    group by transfer_id
    having count(*) > 1
),
valid_from_locations as (
    select location_id from {{ ref('locations') }} where location_id is not null
),
valid_to_locations as (
    select location_id from {{ ref('locations') }} where location_id is not null
),
valid_products as (
    select sku_id from {{ ref('products') }} where sku_id is not null
)

select
    t.transfer_id,
    t.from_location_id,
    t.to_location_id,
    t.sku_id,
    t.qty,
    t.shipped_date,
    t.received_date,
    t.status,
    case
        when t.transfer_id is null then 'Missing primary key transfer_id'
        when d.transfer_id is not null then 'Duplicate transfer_id'
        when t.from_location_id is null or t.to_location_id is null or t.sku_id is null then 'Missing location or product identifiers'
        when t.from_location_id = t.to_location_id then 'Origin and destination locations are identical'
        when t.qty is null or t.qty <= 0 then 'Transfer quantity must be strictly positive (> 0)'
        when t.shipped_date is null then 'Missing shipped_date'
        when t.received_date is not null and t.received_date < t.shipped_date then 'Received date cannot precede shipped date'
        when t.status not in ('COMPLETED', 'IN_TRANSIT', 'CANCELLED') then 'Invalid transfer status'
        when vf.location_id is null then 'Foreign key violation: from_location_id does not exist in locations'
        when vt.location_id is null then 'Foreign key violation: to_location_id does not exist in locations'
        when vp.sku_id is null then 'Foreign key violation: sku_id does not exist in products'
        else 'Transfer validation failure'
    end as failure_reason
from {{ ref('transfers') }} as t
left join duplicates as d
    on t.transfer_id = d.transfer_id
left join valid_from_locations as vf
    on t.from_location_id = vf.location_id
left join valid_to_locations as vt
    on t.to_location_id = vt.location_id
left join valid_products as vp
    on t.sku_id = vp.sku_id
where t.transfer_id is null
   or d.transfer_id is not null
   or t.from_location_id is null
   or t.to_location_id is null
   or t.sku_id is null
   or t.from_location_id = t.to_location_id
   or t.qty is null
   or t.qty <= 0
   or t.shipped_date is null
   or (t.received_date is not null and t.received_date < t.shipped_date)
   or t.status not in ('COMPLETED', 'IN_TRANSIT', 'CANCELLED')
   or vf.location_id is null
   or vt.location_id is null
   or vp.sku_id is null
