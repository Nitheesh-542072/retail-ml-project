{{ config(
    materialized = 'incremental',
    unique_key = ['supplier_id', 'sku_id']
) }}

select
    supplier_id,
    sku_id,
    promised_lead_time_days as contracted_lead_time_days,
    moq,
    contract_unit_cost,
    is_preferred,
    source_file_name,
    ingestion_timestamp
from {{ ref('suppliers') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
