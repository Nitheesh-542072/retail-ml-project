{{ config(
    materialized = 'incremental',
    unique_key = 'location_id'
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_locations') %}

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
{% if err_table %}
left join {{ err_table }} as err
    on b.location_id = err.location_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.location_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
