{{ config(
    materialized = 'incremental',
    unique_key = ['shipment_id', 'event_type', 'event_timestamp']
) }}

select
    b.shipment_id,
    row_number() over (
        partition by b.shipment_id 
        order by b.event_timestamp asc, b.event_type asc
    ) as event_seq,
    b.order_id,
    b.origin_location_id,
    b.carrier_id,
    b.service_level,
    b.ship_timestamp,
    b.delivered_timestamp,
    b.shipping_cost,
    b.event_type,
    b.delay_note,
    b.event_timestamp,
    b.is_late,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('shipments') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
