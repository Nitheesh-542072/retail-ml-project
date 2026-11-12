{{ config(
    materialized = 'incremental',
    unique_key = ['sales_date', 'sku_id', 'location_id', 'channel']
) }}

select
    sales_date,
    sku_id,
    location_id,
    channel,
    units_sold,
    sales_amount,
    avg_selling_price,
    units_returned,
    source_file_name,
    ingestion_timestamp
from {{ ref('sales_demand') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
