{{ config(
    materialized = 'incremental',
    unique_key = 'calendar_date'
) }}

select
    date::date as calendar_date,
    is_holiday::boolean as is_holiday,
    nullif(holiday_name, '')::string as holiday_name,
    week::integer as iso_week,
    month::integer as calendar_month,
    season::string as season,
    is_peak_period::boolean as is_peak_period,
    source_file_name,
    ingestion_timestamp
from
    {{ source('raw', 'calendar_raw') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
