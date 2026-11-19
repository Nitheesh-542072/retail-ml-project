{{ config(
    materialized = 'incremental',
    unique_key = 'supplier_id'
) }}

select
    b.supplier_id,
    b.supplier_name,
    b.country,
    b.is_active,
    max(b.source_file_name) as source_file_name,
    max(b.ingestion_timestamp) as ingestion_timestamp
from {{ ref('suppliers') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
group by
    b.supplier_id,
    b.supplier_name,
    b.country,
    b.is_active
