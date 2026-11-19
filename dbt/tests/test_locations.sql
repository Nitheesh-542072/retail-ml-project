-- Consolidated validation test for locations
-- Covers: null PK, duplicates, valid location_type, region, capacities

with duplicates as (
    select location_id
    from {{ ref('locations') }}
    where location_id is not null
    group by location_id
    having count(*) > 1
)

select
    l.location_id,
    l.location_type,
    l.region,
    case
        when l.location_id is null then 'Missing primary key location_id'
        when d.location_id is not null then 'Duplicate location_id'
        when l.location_type not in ('DC', 'STORE', '3PL') then 'Invalid location_type'
        when l.region is null then 'Missing region'
        when l.storage_capacity < 0 or l.daily_order_capacity < 0 then 'Negative capacity value'
        else 'Location validation failure'
    end as failure_reason
from {{ ref('locations') }} as l
left join duplicates as d
    on l.location_id = d.location_id
where l.location_id is null
   or d.location_id is not null
   or l.location_type not in ('DC', 'STORE', '3PL')
   or l.region is null
   or l.storage_capacity < 0
   or l.daily_order_capacity < 0
