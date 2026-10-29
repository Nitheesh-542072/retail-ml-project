select
    raw_payload:campaign_id::string as campaign_id,
    raw_payload:campaign_name::string as campaign_name,
    raw_payload:channel::string as channel,
    raw_payload:offer.type::string as offer_type,
    raw_payload:offer.promo_code::string as promo_code,
    raw_payload:offer.discount_percentage::integer as discount_percentage,
    raw_payload:offer.min_spend_threshold::number(10, 2) as min_spend_threshold,
    raw_payload:offer.budget_allocated::number(12, 2) as budget_allocated,
    raw_payload:rules.target_segment::string as target_segment,
    raw_payload:rules.exclude_open_support_cases::boolean as exclude_open_support_cases,
    raw_payload:rules.max_contact_frequency_7d::integer as max_contact_frequency_7d,
    raw_payload:schedule.start_date::date as start_date,
    raw_payload:schedule.end_date::date as end_date,
    raw_payload:schedule.status::string as campaign_status,
    raw_payload:metadata.created_by::string as created_by,
    raw_payload:metadata.created_at::timestamp_ntz as created_at,
    source_file_name,
    '{{ source("raw", "campaigns_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'campaigns_raw') }}

