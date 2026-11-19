{{ config(
    materialized = 'incremental',
    unique_key = 'calendar_date'
) }}

select
    b.calendar_date,
    b.is_holiday,
    b.holiday_name,
    b.iso_week as fiscal_week,
    b.calendar_month as fiscal_month,
    b.season,
    b.is_peak_period,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('calendar') }} as b
where 1 = 1
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
