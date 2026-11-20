{{ config(
    materialized = 'incremental',
    unique_key = ['sales_date', 'sku_id', 'location_id', 'channel']
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='TEST_SALES_DEMAND') %}
{% if not err_table %}
  {% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_sales_demand') %}
{% endif %}

select
    b.sales_date,
    b.sku_id,
    b.location_id,
    b.channel,
    b.units_sold,
    b.sales_amount,
    b.avg_selling_price,
    b.units_returned,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('sales_demand') }} as b
{% if err_table %}
left join {{ err_table }} as err
    on b.sales_date = err.sales_date
   and b.sku_id = err.sku_id
   and b.location_id = err.location_id
   and b.channel = err.channel
{% endif %}
where 1 = 1
{% if err_table %}
  and err.sku_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
