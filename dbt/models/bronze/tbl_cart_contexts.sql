select
    raw_payload:cart_id::string as cart_id,
    raw_payload:session_id::string as session_id,
    raw_payload:customer_id::string as customer_id,
    raw_payload:totals.cart_value::number(10, 2) as cart_value,
    raw_payload:totals.item_count::integer as item_count,
    raw_payload:context.primary_category::string as primary_category,
    raw_payload:context.cart_status::string as cart_status,
    raw_payload:items as items_array,
    raw_payload:cart_timestamp::timestamp_ntz as cart_timestamp,
    source_file_name,
    '{{ source("raw", "cart_contexts_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'cart_contexts_raw') }}

