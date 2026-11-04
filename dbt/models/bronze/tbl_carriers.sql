select
    carrier_id::string as carrier_id,
    carrier_name::string as carrier_name,
    service_level::string as service_level,
    promised_transit_days::integer as promised_transit_days,
    base_rate::number(6, 2) as base_rate,
    source_file_name,
    '{{ source("raw", "carriers_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'carriers_raw') }}

