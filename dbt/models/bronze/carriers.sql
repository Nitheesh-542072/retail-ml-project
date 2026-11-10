{{ config(
    materialized = 'incremental',
    unique_key = 'carrier_id'
) }}

select
    carrier_id::string as carrier_id,
    carrier_name::string as carrier_name,
    service_level::string as service_level,
    promised_transit_days::integer as promised_transit_days,
    base_rate::number(6, 2) as base_rate,
    source_file_name,
    ingestion_timestamp
from
    {{ source('raw', 'carriers_raw') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
