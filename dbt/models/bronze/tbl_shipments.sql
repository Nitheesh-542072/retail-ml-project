select
    raw_payload:shipment_id::string as shipment_id,
    raw_payload:order_id::string as order_id,
    raw_payload:origin_location_id::string as origin_location_id,
    raw_payload:carrier_id::string as carrier_id,
    raw_payload:service_level::string as service_level,
    raw_payload:ship_timestamp::timestamp_ntz as ship_timestamp,
    raw_payload:delivered_timestamp::timestamp_ntz as delivered_timestamp,
    raw_payload:shipping_cost::number(8, 2) as shipping_cost,
    event.value:event_type::string as event_type,
    event.value:delay_note::string as delay_note,
    source_file_name,
    '{{ source("raw", "shipments_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'shipments_raw') }},
    lateral flatten(input => raw_payload:tracking_events) as event
