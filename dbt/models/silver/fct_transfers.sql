{{ config(
    materialized = 'incremental',
    unique_key = 'transfer_id'
) }}

select
    b.transfer_id,
    b.from_location_id,
    b.to_location_id,
    b.sku_id,
    b.qty,
    b.shipped_date,
    b.received_date,
    b.status,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('transfers') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
