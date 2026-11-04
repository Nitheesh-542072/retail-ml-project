select
    sku_id::string as sku_id,
    product_name::string as product_name,
    category::string as category,
    brand::string as brand,
    abc_class::string as abc_class,
    unit_cost::number(10, 2) as unit_cost,
    unit_price::number(10, 2) as unit_price,
    case_pack_qty::integer as case_pack_qty,
    weight_kg::number(6, 2) as weight_kg,
    nullif(shelf_life_days, '')::integer as shelf_life_days,
    status::string as status,
    launch_date::date as launch_date,
    source_file_name,
    '{{ source("raw", "products_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'products_raw') }}

