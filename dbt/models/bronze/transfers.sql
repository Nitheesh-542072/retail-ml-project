{{ config(
    materialized = 'incremental',
    unique_key = 'transfer_id'
) }}

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
    ingestion_timestamp
from
    {{ source('raw', 'transfers_raw') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
