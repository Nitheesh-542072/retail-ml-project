{{ config(
    materialized = 'incremental',
    unique_key = 'carrier_id'
) }}

select
    carrier_id,
    carrier_name,
    service_level,
    promised_transit_days,
    base_rate,
    source_file_name,
    ingestion_timestamp
from {{ ref('carriers') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
