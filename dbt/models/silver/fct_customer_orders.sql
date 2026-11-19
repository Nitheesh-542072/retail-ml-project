{{ config(
    materialized = 'incremental',
    unique_key = ['order_id', 'sku_id']
) }}

select
    b.order_id,
    b.sku_id,
    b.customer_id,
    b.customer_name,
    b.address,
    b.phone,
    b.delivery_postal_code,
    b.delivery_region,
    b.order_timestamp,
    b.promised_delivery_date,
    b.service_level,
    b.fulfilled_from_location_id,
    b.qty,
    b.unit_price,
    b.order_status,
    b.is_split_shipment,
    b.order_subtotal,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('customer_orders') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
