{{ config(
    materialized = 'incremental',
    unique_key = 'supplier_id'
) }}

select
    supplier_id,
    supplier_name,
    country,
    is_active,
    max(source_file_name) as source_file_name,
    max(ingestion_timestamp) as ingestion_timestamp
from {{ ref('suppliers') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}

group by
    supplier_id,
    supplier_name,
    country,
    is_active
