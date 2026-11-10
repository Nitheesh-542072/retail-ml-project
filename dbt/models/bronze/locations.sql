{{ config(
    materialized = 'incremental',
    unique_key = 'location_id'
) }}

select
    location_id::string as location_id,
    location_type::string as location_type,
    region::string as region,
    postal_code::string as postal_code,
    latitude::float as latitude,
    longitude::float as longitude,
    nullif(parent_dc_id, '')::string as parent_dc_id,
    storage_capacity::integer as storage_capacity,
    daily_order_capacity::integer as daily_order_capacity,
    cutoff_time::time as cutoff_time,
    is_active::boolean as is_active,
    source_file_name,
    ingestion_timestamp
from
    {{ source('raw', 'locations_raw') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
