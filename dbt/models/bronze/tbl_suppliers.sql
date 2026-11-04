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
    '{{ source("raw", "suppliers_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'suppliers_raw') }}

