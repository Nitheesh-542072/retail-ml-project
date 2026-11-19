{{ config(
    materialized = 'incremental',
    unique_key = 'movement_id'
) }}

select
    b.movement_id,
    b.sku_id,
    b.location_id,
    b.movement_type,
    b.quantity,
    b.reference_id,
    b.reason_code,
    b.movement_timestamp as event_timestamp,
    b.movement_timestamp,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('inventory_movements') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
