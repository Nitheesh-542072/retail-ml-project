select
    raw_payload:promo_id::string as promo_id,
    raw_payload:promo_name::string as promo_name,
    raw_payload:promo_type::string as promo_type,
    raw_payload:discount_pct::integer as discount_pct,
    raw_payload:applicable_skus as applicable_skus,
    raw_payload:applicable_categories as applicable_categories,
    raw_payload:applicable_regions as applicable_regions,
    raw_payload:start_date::date as start_date,
    raw_payload:end_date::date as end_date,
    raw_payload:status::string as promo_status,
    source_file_name,
    '{{ source("raw", "promotions_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'promotions_raw') }}

