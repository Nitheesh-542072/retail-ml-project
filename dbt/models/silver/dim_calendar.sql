{{ config(
    materialized = 'incremental',
    unique_key = 'calendar_date'
) }}

select
    calendar_date,
    is_holiday,
    holiday_name,
    iso_week as fiscal_week,
    calendar_month as fiscal_month,
    season,
    is_peak_period,
    source_file_name,
    ingestion_timestamp
from {{ ref('calendar') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
