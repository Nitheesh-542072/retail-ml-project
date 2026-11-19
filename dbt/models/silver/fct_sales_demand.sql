{{ config(
    materialized = 'incremental',
    unique_key = ['sales_date', 'sku_id', 'location_id', 'channel']
) }}

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
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
