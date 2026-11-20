{{ config(
    materialized = 'incremental',
    unique_key = 'supplier_id'
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='TEST_SUPPLIERS') %}
{% if not err_table %}
  {% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_suppliers') %}
{% endif %}

select
    b.supplier_id,
    b.supplier_name,
    b.country,
    b.is_active,
    max(b.source_file_name) as source_file_name,
    max(b.ingestion_timestamp) as ingestion_timestamp
from {{ ref('suppliers') }} as b
{% if err_table %}
left join {{ err_table }} as err
    on b.supplier_id = err.supplier_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.supplier_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
group by
    b.supplier_id,
    b.supplier_name,
    b.country,
    b.is_active
