select
    transfer_id::string as transfer_id,
    from_location_id::string as from_location_id,
    to_location_id::string as to_location_id,
    sku_id::string as sku_id,
    qty::integer as qty,
    shipped_date::date as shipped_date,
    nullif(received_date, '')::date as received_date,
    status::string as status,
    source_file_name,
    '{{ source("raw", "transfers_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'transfers_raw') }}

