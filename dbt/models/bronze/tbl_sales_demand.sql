select
    sales_date::date as sales_date,
    sku_id::string as sku_id,
    location_id::string as location_id,
    channel::string as channel,
    units_sold::integer as units_sold,
    sales_amount::number(10, 2) as sales_amount,
    avg_selling_price::number(10, 2) as avg_selling_price,
    units_returned::integer as units_returned,
    source_file_name,
    '{{ source("raw", "sales_demand_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'sales_demand_raw') }}

