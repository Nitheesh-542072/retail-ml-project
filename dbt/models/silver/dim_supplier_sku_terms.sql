{{ config(
    materialized = 'incremental',
    unique_key = ['supplier_id', 'sku_id']
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='TEST_SUPPLIERS') %}
{% if not err_table %}
  {% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_suppliers') %}
{% endif %}

select
    b.supplier_id,
    b.sku_id,
    b.promised_lead_time_days as contracted_lead_time_days,
    b.moq,
    b.contract_unit_cost,
    b.is_preferred,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('suppliers') }} as b
{% if err_table %}
left join {{ err_table }} as err
    on b.supplier_id = err.supplier_id
   and b.sku_id = err.sku_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.supplier_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
