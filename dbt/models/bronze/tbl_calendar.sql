select
    date::date as calendar_date,
    is_holiday::boolean as is_holiday,
    nullif(holiday_name, '')::string as holiday_name,
    week::integer as iso_week,
    month::integer as calendar_month,
    season::string as season,
    is_peak_period::boolean as is_peak_period,
    source_file_name,
    '{{ source("raw", "calendar_raw").name | upper }}' as source_table_name,
    current_timestamp() as ingestion_timestamp
from
    {{ source('raw', 'calendar_raw') }}

