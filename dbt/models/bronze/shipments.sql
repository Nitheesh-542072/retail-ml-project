{{ config(
    materialized = 'incremental',
    unique_key = ['shipment_id', 'event_type', 'event_timestamp']
) }}

select
    raw_payload:shipment_id::string as shipment_id,
    raw_payload:order_id::string as order_id,
    raw_payload:origin_location_id::string as origin_location_id,
    raw_payload:carrier_id::string as carrier_id,
    raw_payload:service_level::string as service_level,
    raw_payload:ship_timestamp::timestamp_ntz as ship_timestamp,
    raw_payload:delivered_timestamp::timestamp_ntz as delivered_timestamp,
    raw_payload:shipping_cost::number(8, 2) as shipping_cost,
    raw_payload:is_late::boolean as is_late,
    event.value:event_type::string as event_type,
    event.value:delay_note::string as delay_note,
    event.value:timestamp::timestamp_ntz as event_timestamp,
    source_file_name,
    ingestion_timestamp
from
    {{ source('raw', 'shipments_raw') }},
    lateral flatten(input => raw_payload:tracking_events) as event

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
