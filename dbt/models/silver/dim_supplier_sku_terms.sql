{{ config(
    materialized = 'incremental',
    unique_key = ['supplier_id', 'sku_id']
) }}

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
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
