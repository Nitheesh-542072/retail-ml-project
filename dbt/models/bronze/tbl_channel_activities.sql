select
    raw_payload:activity_id::string as activity_id,
    raw_payload:customer_id::string as customer_id,
    raw_payload:channel::string as channel,
    raw_payload:session.session_id::string as session_id,
    raw_payload:session.device_type::string as device_type,
    raw_payload:activity.event_type_detail::string as event_type_detail,
    raw_payload:activity.page_category::string as page_category,
    raw_payload:activity.duration_seconds::integer as duration_seconds,
    raw_payload:timestamp::timestamp_ntz as activity_timestamp,
    source_file_name,
    '{{ source("raw", "channel_activities_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'channel_activities_raw') }}

