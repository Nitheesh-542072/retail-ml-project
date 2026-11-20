{{ config(
    materialized = 'incremental',
    unique_key = ['order_id', 'sku_id']
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='TEST_CUSTOMER_ORDERS') %}
{% if not err_table %}
  {% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_customer_orders') %}
{% endif %}

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
{% if err_table %}
left join {{ err_table }} as err
    on b.order_id = err.order_id
   and b.sku_id = err.sku_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.order_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
