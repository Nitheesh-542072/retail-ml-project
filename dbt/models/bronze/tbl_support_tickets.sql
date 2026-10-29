select
    raw_payload:ticket_id::string as ticket_id,
    raw_payload:customer_id::string as customer_id,
    raw_payload:ticket_details.category::string as category,
    raw_payload:ticket_details.severity::string as severity,
    raw_payload:ticket_details.contact_channel::string as contact_channel,
    raw_payload:resolution.ticket_status::string as ticket_status,
    raw_payload:resolution.is_escalated::boolean as is_escalated,
    raw_payload:resolution.resolution_time_hours::number(6, 1) as resolution_time_hours,
    raw_payload:resolution.satisfaction_score::integer as satisfaction_score,
    raw_payload:timestamp::timestamp_ntz as ticket_timestamp,
    source_file_name,
    '{{ source("raw", "support_tickets_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'support_tickets_raw') }}

