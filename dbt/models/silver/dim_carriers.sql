{{ config(
    materialized = 'incremental',
    unique_key = 'carrier_id'
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='TEST_CARRIERS') %}
{% if not err_table %}
  {% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_carriers') %}
{% endif %}

select
    b.carrier_id,
    b.carrier_name,
    b.service_level,
    b.promised_transit_days,
    b.base_rate,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('carriers') }} as b
{% if err_table %}
left join {{ err_table }} as err
    on b.carrier_id = err.carrier_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.carrier_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
