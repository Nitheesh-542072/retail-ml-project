{{ config(
    materialized = 'incremental',
    unique_key = ['order_id', 'sku_id']
) }}

select
    order_id,
    sku_id,
    customer_id,
    customer_name,
    address,
    phone,
    delivery_postal_code,
    delivery_region,
    order_timestamp,
    promised_delivery_date,
    service_level,
    fulfilled_from_location_id,
    qty,
    unit_price,
    order_status,
    is_split_shipment,
    order_subtotal,
    source_file_name,
    ingestion_timestamp
from {{ ref('customer_orders') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
