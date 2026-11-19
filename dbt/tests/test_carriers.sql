-- Consolidated validation test for carriers
-- Covers: null PK, duplicates, carrier_name, service_level, transit days, base rates

with duplicates as (
    select carrier_id
    from {{ ref('carriers') }}
    where carrier_id is not null
    group by carrier_id
    having count(*) > 1
)

select
    c.carrier_id,
    c.carrier_name,
    c.service_level,
    case
        when c.carrier_id is null then 'Missing primary key carrier_id'
        when d.carrier_id is not null then 'Duplicate carrier_id'
        when c.carrier_name is null then 'Missing carrier_name'
        when c.service_level not in ('SAME_DAY', 'NEXT_DAY', 'STANDARD') then 'Invalid carrier service_level'
        when c.promised_transit_days < 0 then 'Negative promised transit days'
        when c.base_rate < 0 then 'Negative base rate'
        else 'Carrier validation failure'
    end as failure_reason
from {{ ref('carriers') }} as c
left join duplicates as d
    on c.carrier_id = d.carrier_id
where c.carrier_id is null
   or d.carrier_id is not null
   or c.carrier_name is null
   or c.service_level not in ('SAME_DAY', 'NEXT_DAY', 'STANDARD')
   or c.promised_transit_days < 0
   or c.base_rate < 0
