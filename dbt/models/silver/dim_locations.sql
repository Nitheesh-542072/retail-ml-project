{{ config(
    materialized = 'incremental',
    unique_key = 'location_id'
) }}

select
    b.location_id,
    b.location_type,
    b.region,
    b.postal_code,
    b.latitude,
    b.longitude,
    b.parent_dc_id,
    b.storage_capacity,
    b.daily_order_capacity,
    b.cutoff_time,
    b.is_active,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('locations') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
