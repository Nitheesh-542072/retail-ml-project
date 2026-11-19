-- Consolidated validation test for shipments
-- Covers: composite PK nulls, duplicates, delivery chronology, shipping cost, event types, service levels, foreign keys

with duplicates as (
    select shipment_id, event_type, event_timestamp
    from {{ ref('shipments') }}
    where shipment_id is not null and event_type is not null and event_timestamp is not null
    group by shipment_id, event_type, event_timestamp
    having count(*) > 1
),
valid_locations as (
    select location_id from {{ ref('locations') }} where location_id is not null
),
valid_carriers as (
    select carrier_id from {{ ref('carriers') }} where carrier_id is not null
)

select
    sh.shipment_id,
    sh.event_type,
    sh.event_timestamp,
    sh.order_id,
    sh.origin_location_id,
    sh.carrier_id,
    sh.service_level,
    sh.ship_timestamp,
    sh.delivered_timestamp,
    sh.shipping_cost,
    case
        when sh.shipment_id is null or sh.event_type is null or sh.event_timestamp is null then 'Missing composite primary key components'
        when d.shipment_id is not null then 'Duplicate shipment tracking event'
        when sh.order_id is null then 'Missing order_id'
        when sh.origin_location_id is null then 'Missing origin_location_id'
        when sh.carrier_id is null then 'Missing carrier_id'
        when sh.ship_timestamp is null then 'Missing ship_timestamp'
        when sh.delivered_timestamp is not null and sh.delivered_timestamp < sh.ship_timestamp then 'Delivered timestamp precedes ship timestamp'
        when sh.shipping_cost is null or sh.shipping_cost < 0 then 'Invalid shipping cost (cannot be negative)'
        when sh.service_level not in ('SAME_DAY', 'NEXT_DAY', 'STANDARD') then 'Invalid service_level'
        when sh.event_type not in ('PICKED_UP', 'IN_TRANSIT', 'DELAYED', 'DELIVERED') then 'Invalid event_type'
        when vl.location_id is null then 'Foreign key violation: origin_location_id does not exist in locations'
        when vc.carrier_id is null then 'Foreign key violation: carrier_id does not exist in carriers'
        else 'Shipment validation failure'
    end as failure_reason
from {{ ref('shipments') }} as sh
left join duplicates as d
    on sh.shipment_id = d.shipment_id
   and sh.event_type = d.event_type
   and sh.event_timestamp = d.event_timestamp
left join valid_locations as vl
    on sh.origin_location_id = vl.location_id
left join valid_carriers as vc
    on sh.carrier_id = vc.carrier_id
where sh.shipment_id is null
   or sh.event_type is null
   or sh.event_timestamp is null
   or d.shipment_id is not null
   or sh.order_id is null
   or sh.origin_location_id is null
   or sh.carrier_id is null
   or sh.ship_timestamp is null
   or (sh.delivered_timestamp is not null and sh.delivered_timestamp < sh.ship_timestamp)
   or sh.shipping_cost is null
   or sh.shipping_cost < 0
   or sh.service_level not in ('SAME_DAY', 'NEXT_DAY', 'STANDARD')
   or sh.event_type not in ('PICKED_UP', 'IN_TRANSIT', 'DELAYED', 'DELIVERED')
   or vl.location_id is null
   or vc.carrier_id is null
