select
    raw_payload:customer_id::string as customer_id,
    raw_payload:profile.first_name::string as first_name,
    raw_payload:profile.last_name::string as last_name,
    raw_payload:profile.age::integer as age,
    raw_payload:profile.gender::string as gender,
    raw_payload:contact.email::string as email,
    raw_payload:contact.phone::string as phone,
    raw_payload:contact.address.state::string as state,
    raw_payload:contact.address.zip_code::string as zip_code,
    raw_payload:loyalty.tier::string as loyalty_tier,
    raw_payload:loyalty.points_balance::integer as points_balance,
    raw_payload:loyalty.signup_channel::string as signup_channel,
    raw_payload:preferences.preferred_channel::string as preferred_channel,
    raw_payload:preferences.max_weekly_touchpoints::integer as max_weekly_touchpoints,
    raw_payload:consent.email::boolean as consent_email,
    raw_payload:consent.sms::boolean as consent_sms,
    raw_payload:consent.push::boolean as consent_push,
    raw_payload:status.is_active::boolean as is_active,
    raw_payload:status.created_at::timestamp_ntz as created_at,
    raw_payload:status.updated_at::timestamp_ntz as updated_at,
    source_file_name,
    '{{ source("raw", "customer_profiles_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'customer_profiles_raw') }}

