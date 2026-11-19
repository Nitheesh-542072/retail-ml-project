{{ config(
    materialized = 'table',
    unique_key = ['order_date', 'location_id', 'carrier_id']
) }}

-- Curated gold fact: daily logistics performance
-- Metrics: orders shipped, carrier on-time %, average shipping cost
-- Reference: inventory_fulfilment_data_model_v1.md section 2.2

with distinct_shipments as (
    select
        shipment_id,
        order_id,
        origin_location_id,
        carrier_id,
        service_level,
        min(ship_timestamp) as ship_timestamp,
        max(delivered_timestamp) as delivered_timestamp,
        max(shipping_cost) as shipping_cost,
        boolor_agg(coalesce(is_late, false)) as is_late
    from {{ ref('fct_shipments') }}
    group by shipment_id, order_id, origin_location_id, carrier_id, service_level
),

order_shipment as (
    select
        o.order_id,
        o.order_timestamp::date as order_date,
        o.fulfilled_from_location_id as location_id,
        s.carrier_id,
        coalesce(s.service_level, o.service_level) as service_level,
        s.shipment_id,
        s.ship_timestamp,
        s.delivered_timestamp,
        s.shipping_cost,
        s.is_late
    from (
        select distinct
            order_id,
            order_timestamp,
            fulfilled_from_location_id,
            service_level
        from {{ ref('fct_customer_orders') }}
    ) as o
    inner join distinct_shipments as s
        on o.order_id = s.order_id
)

select
    os.order_date,
    os.location_id,
    os.carrier_id,
    l.location_type,
    l.region,
    c.carrier_name,
    c.service_level,
    c.promised_transit_days,
    c.base_rate,
    count(distinct os.order_id) as total_orders_shipped,
    count(distinct case when os.delivered_timestamp is not null then os.order_id end) as total_orders_delivered,
    count(distinct case when os.delivered_timestamp is not null and os.is_late = false then os.order_id end) as on_time_deliveries,
    count(distinct case when os.is_late = true then os.order_id end) as late_deliveries,
    round(
        100.0 * count(distinct case when os.delivered_timestamp is not null and os.is_late = false then os.order_id end)
        / nullif(count(distinct case when os.delivered_timestamp is not null then os.order_id end), 0),
        2
    ) as carrier_on_time_pct,
    round(avg(datediff(hour, os.ship_timestamp, os.delivered_timestamp) / 24.0), 2) as avg_transit_days,
    round(avg(os.shipping_cost), 2) as avg_shipping_cost,
    round(sum(os.shipping_cost), 2) as total_shipping_cost
from order_shipment as os
left join {{ ref('dim_locations') }} as l
    on os.location_id = l.location_id
left join {{ ref('dim_carriers') }} as c
    on os.carrier_id = c.carrier_id
group by
    os.order_date,
    os.location_id,
    os.carrier_id,
    l.location_type,
    l.region,
    c.carrier_name,
    c.service_level,
    c.promised_transit_days,
    c.base_rate
