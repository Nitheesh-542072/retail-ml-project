{{ config(
    materialized = 'table',
    unique_key = ['snapshot_date', 'sku_id', 'location_id']
) }}

-- Pre-joined curated gold fact: daily stock + 14-day rolling demand + open supply + days of supply (DOS)
-- Reference: inventory_fulfilment_data_model_v1.md section 2.2

with daily_demand as (
    select
        sales_date,
        sku_id,
        location_id,
        sum(units_sold) as daily_units_sold
    from {{ ref('fct_sales_demand') }}
    group by sales_date, sku_id, location_id
),

open_pos as (
    select
        destination_location_id as location_id,
        sku_id,
        sum(ordered_qty - coalesce(received_qty, 0)) as open_po_qty
    from {{ ref('fct_purchase_orders') }}
    where status in ('OPEN', 'PARTIAL')
    group by destination_location_id, sku_id
),

open_transfers as (
    select
        to_location_id as location_id,
        sku_id,
        sum(qty) as open_transfer_in_qty
    from {{ ref('fct_transfers') }}
    where status = 'IN_TRANSIT'
    group by to_location_id, sku_id
),

snapshots as (
    select
        snapshot_date,
        sku_id,
        location_id,
        on_hand_qty,
        reserved_qty,
        available_qty,
        in_transit_qty,
        damaged_qty,
        safety_stock_qty,
        is_stockout
    from {{ ref('fct_inventory_snapshots') }}
),

rolling_metrics as (
    select
        s.snapshot_date,
        s.sku_id,
        s.location_id,
        coalesce(sum(d.daily_units_sold), 0) as rolling_demand_14d,
        round(coalesce(sum(d.daily_units_sold), 0) / 14.0, 2) as avg_daily_demand_14d
    from snapshots as s
    left join daily_demand as d
        on s.sku_id = d.sku_id
       and s.location_id = d.location_id
       and d.sales_date between dateadd(day, -13, s.snapshot_date) and s.snapshot_date
    group by s.snapshot_date, s.sku_id, s.location_id
)

select
    s.snapshot_date,
    s.sku_id,
    s.location_id,
    p.product_name,
    p.category,
    p.abc_class,
    l.location_type,
    l.region,
    s.on_hand_qty,
    s.reserved_qty,
    s.available_qty,
    s.in_transit_qty,
    s.damaged_qty,
    s.safety_stock_qty,
    s.is_stockout,
    r.rolling_demand_14d,
    r.avg_daily_demand_14d,
    coalesce(po.open_po_qty, 0) as open_po_qty,
    coalesce(tr.open_transfer_in_qty, 0) as open_transfer_in_qty,
    (s.available_qty + coalesce(po.open_po_qty, 0) + coalesce(tr.open_transfer_in_qty, 0)) as total_projected_supply,
    case
        when r.avg_daily_demand_14d > 0 then round(s.available_qty / r.avg_daily_demand_14d, 1)
        else 999.0
    end as days_of_supply,
    round(s.on_hand_qty * coalesce(p.unit_cost, 0), 2) as inventory_value,
    case
        when s.available_qty < s.safety_stock_qty then true
        else false
    end as is_below_safety_stock,
    case
        when s.available_qty <= 0 or (r.avg_daily_demand_14d > 0 and (s.available_qty / r.avg_daily_demand_14d) < 3.0) then true
        else false
    end as stockout_risk_flag
from snapshots as s
inner join rolling_metrics as r
    on s.snapshot_date = r.snapshot_date
   and s.sku_id = r.sku_id
   and s.location_id = r.location_id
left join {{ ref('dim_products') }} as p
    on s.sku_id = p.sku_id
left join {{ ref('dim_locations') }} as l
    on s.location_id = l.location_id
left join open_pos as po
    on s.location_id = po.location_id
   and s.sku_id = po.sku_id
left join open_transfers as tr
    on s.location_id = tr.location_id
   and s.sku_id = tr.sku_id
