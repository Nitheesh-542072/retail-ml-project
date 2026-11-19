{{ config(
    materialized = 'incremental',
    unique_key = 'movement_id'
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_inventory_movements') %}

select
    b.movement_id,
    b.sku_id,
    b.location_id,
    b.movement_type,
    b.quantity,
    b.reference_id,
    b.reason_code,
    b.movement_timestamp as event_timestamp,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('inventory_movements') }} as b
{% if err_table %}
left join {{ err_table }} as err
    on b.movement_id = err.movement_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.movement_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
