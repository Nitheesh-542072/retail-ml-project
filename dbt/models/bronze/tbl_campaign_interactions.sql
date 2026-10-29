select
    raw_payload:interaction_id::string as interaction_id,
    raw_payload:customer_id::string as customer_id,
    raw_payload:campaign_id::string as campaign_id,
    raw_payload:channel::string as channel,
    raw_payload:response.action::string as response_action,
    raw_payload:response.details.promo_code_used::string as promo_code_used,
    raw_payload:response.details.redemption_value::number(10, 2) as redemption_value,
    raw_payload:response.details.click_url::string as click_url,
    raw_payload:response.details.time_on_page_seconds::integer as time_on_page_seconds,
    raw_payload:timestamp::timestamp_ntz as interaction_timestamp,
    source_file_name,
    '{{ source("raw", "campaign_interactions_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'campaign_interactions_raw') }}

