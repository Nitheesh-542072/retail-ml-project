{{ config(
    materialized = 'incremental',
    unique_key = ['supplier_id', 'sku_id']
) }}

select
    supplier_id::string as supplier_id,
    supplier_name::string as supplier_name,
    country::string as country,
    promised_lead_time_days::integer as promised_lead_time_days,
    sku_id::string as sku_id,
    moq::integer as moq,
    contract_unit_cost::number(10, 2) as contract_unit_cost,
    is_preferred::boolean as is_preferred,
    is_active::boolean as is_active,
    source_file_name,
    ingestion_timestamp
from
    {{ source('raw', 'suppliers_raw') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
