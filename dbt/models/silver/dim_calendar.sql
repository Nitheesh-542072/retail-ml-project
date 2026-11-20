{{ config(
    materialized = 'incremental',
    unique_key = 'calendar_date'
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_calendar') %}

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
{% if err_table %}
left join {{ err_table }} as err
    on b.calendar_date = err.calendar_date
{% endif %}
where 1 = 1
{% if err_table %}
  and err.calendar_date is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
