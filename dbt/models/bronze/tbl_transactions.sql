select
    raw_payload:transaction_id::string as transaction_id,
    raw_payload:customer_id::string as customer_id,
    raw_payload:store_id::string as store_id,
    raw_payload:channel::string as channel,
    raw_payload:payment.method::string as payment_method,
    raw_payload:payment.promo_code_applied::string as promo_code_applied,
    raw_payload:totals.gross_total::number(12, 2) as gross_total,
    raw_payload:totals.discount_total::number(12, 2) as discount_total,
    raw_payload:totals.net_total::number(12, 2) as net_total,
    raw_payload:items as items_array,
    raw_payload:timestamp::timestamp_ntz as transaction_timestamp,
    source_file_name,
    '{{ source("raw", "transactions_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'transactions_raw') }}

