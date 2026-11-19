{{ config(
    materialized = 'view'
) }}

-- Feature View: FV_ORDER_FULFILMENT_RISK
-- Used by M3 Late Delivery Risk & Sourcing Node Optimization
-- Features: node_daily_backlog_ratio, carrier_on_time_rate_30d, is_peak_period_active, avg_transit_days_30d
-- Reference: inventory_fulfilment_data_model_v1.md section 2.2

with node_backlog as (
    select
        fulfilled_from_location_id as location_id,
        count(distinct case when order_status in ('CREATED', 'PACKED') then order_id end) as open_backlog_orders
    from {{ ref('fct_customer_orders') }}
    group by fulfilled_from_location_id
),

carrier_perf_30d as (
    select
        carrier_id,
        origin_location_id as location_id,
        count(distinct shipment_id) as total_shipments_30d,
        count(distinct case when delivered_timestamp is not null and is_late = false then shipment_id end) as on_time_shipments_30d,
        round(
            count(distinct case when delivered_timestamp is not null and is_late = false then shipment_id end)
            / nullif(count(distinct case when delivered_timestamp is not null then shipment_id end), 0),
            4
        ) as carrier_on_time_rate_30d,
        round(avg(datediff(hour, ship_timestamp, delivered_timestamp) / 24.0), 2) as avg_transit_days_30d
    from {{ ref('fct_shipments') }}
    where ship_timestamp >= dateadd(day, -30, current_timestamp())
    group by carrier_id, origin_location_id
),

peak_calendar as (
    select
        is_peak_period
    from {{ ref('dim_calendar') }}
    where calendar_date = current_date()
    limit 1
),

node_carrier_matrix as (
    select distinct
        l.location_id,
        c.carrier_id
    from {{ ref('dim_locations') }} as l
    cross join {{ ref('dim_carriers') }} as c
)

select
    m.location_id,
    m.carrier_id,
    l.location_type,
    l.region as location_region,
    l.daily_order_capacity,
    c.carrier_name,
    c.service_level,
    c.promised_transit_days,
    c.base_rate,
    coalesce(nb.open_backlog_orders, 0) as open_backlog_orders,
    round(
        coalesce(nb.open_backlog_orders, 0) / nullif(l.daily_order_capacity, 0),
        3
    ) as node_daily_backlog_ratio,
    coalesce(cp.carrier_on_time_rate_30d, 0.9500) as carrier_on_time_rate_30d,
    coalesce(cp.avg_transit_days_30d, c.promised_transit_days::float) as avg_transit_days_30d,
    coalesce((select is_peak_period from peak_calendar), false) as is_peak_period_active
from node_carrier_matrix as m
left join {{ ref('dim_locations') }} as l
    on m.location_id = l.location_id
left join {{ ref('dim_carriers') }} as c
    on m.carrier_id = c.carrier_id
left join node_backlog as nb
    on m.location_id = nb.location_id
left join carrier_perf_30d as cp
    on m.location_id = cp.location_id
   and m.carrier_id = cp.carrier_id
