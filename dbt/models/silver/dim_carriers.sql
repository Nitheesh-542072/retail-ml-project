{{ config(
    materialized = 'incremental',
    unique_key = 'carrier_id'
) }}

select
    b.carrier_id,
    b.carrier_name,
    b.service_level,
    b.promised_transit_days,
    b.base_rate,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('carriers') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
