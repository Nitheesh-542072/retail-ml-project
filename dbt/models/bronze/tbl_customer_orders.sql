select
    raw_payload:order_id::string as order_id,
    raw_payload:customer_id::string as customer_id,
    raw_payload:customer_details:customer_name::string as customer_name,
    raw_payload:customer_details:address::string as customer_address,
    raw_payload:customer_details:phone::string as customer_phone,
    raw_payload:delivery:delivery_postal_code::string as delivery_postal_code,
    raw_payload:delivery:delivery_region::string as delivery_region,
    raw_payload:order_timestamp::timestamp_ntz as order_timestamp,
    raw_payload:promised_delivery_date::date as promised_delivery_date,
    raw_payload:service_level::string as service_level,
    raw_payload:fulfilled_from_location_id::string as fulfilled_from_location_id,
    raw_payload:order_status::string as order_status,
    raw_payload:is_split_shipment::boolean as is_split_shipment,
    raw_payload:order_subtotal::number(10, 2) as order_subtotal,
    raw_payload:items as items_array,
    source_file_name,
    '{{ source("raw", "customer_orders_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'customer_orders_raw') }}

