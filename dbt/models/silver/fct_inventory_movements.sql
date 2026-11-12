{{ config(
    materialized = 'incremental',
    unique_key = 'movement_id'
) }}

select
    movement_id,
    sku_id,
    location_id,
    movement_type,
    quantity,
    reference_id,
    reason_code,
    movement_timestamp as event_timestamp,
    source_file_name,
    ingestion_timestamp
from {{ ref('inventory_movements') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
