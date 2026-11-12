{{ config(
    materialized = 'incremental',
    unique_key = 'location_id'
) }}

select
    location_id,
    location_type,
    region,
    postal_code,
    latitude,
    longitude,
    parent_dc_id,
    storage_capacity,
    daily_order_capacity,
    cutoff_time,
    is_active,
    source_file_name,
    ingestion_timestamp
from {{ ref('locations') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
