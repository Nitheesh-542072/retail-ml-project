select
    raw_payload:product_id::string as product_id,
    raw_payload:product_name::string as product_name,
    raw_payload:brand::string as brand,
    raw_payload:category::string as category,
    raw_payload:sub_category::string as sub_category,
    raw_payload:pricing.base_price::number(10, 2) as base_price,
    raw_payload:pricing.cost_price::number(10, 2) as cost_price,
    raw_payload:pricing.margin_rate::number(10, 4) as margin_rate,
    raw_payload:flags.is_clearance::boolean as is_clearance,
    raw_payload:flags.is_active::boolean as is_active,
    raw_payload:status.created_at::timestamp_ntz as created_at,
    raw_payload:status.updated_at::timestamp_ntz as updated_at,
    source_file_name,
    '{{ source("raw", "product_catalog_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp 
from
    {{ source('raw', 'product_catalog_raw') }}
