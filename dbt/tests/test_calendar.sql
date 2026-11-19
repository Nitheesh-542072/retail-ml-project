-- Consolidated validation test for calendar
-- Covers: null PK, duplicates, null flags

with duplicates as (
    select calendar_date
    from {{ ref('calendar') }}
    where calendar_date is not null
    group by calendar_date
    having count(*) > 1
)

select
    c.calendar_date,
    case
        when c.calendar_date is null then 'Missing primary key calendar_date'
        when d.calendar_date is not null then 'Duplicate calendar_date'
        when c.is_holiday is null then 'Missing is_holiday flag'
        when c.is_peak_period is null then 'Missing is_peak_period flag'
        else 'Calendar validation failure'
    end as failure_reason
from {{ ref('calendar') }} as c
left join duplicates as d
    on c.calendar_date = d.calendar_date
where c.calendar_date is null
   or d.calendar_date is not null
   or c.is_holiday is null
   or c.is_peak_period is null
