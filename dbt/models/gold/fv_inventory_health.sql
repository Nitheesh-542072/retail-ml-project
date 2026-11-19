{{ config(
    materialized = 'view'
) }}

-- Feature View: FV_INVENTORY_HEALTH
-- Used by M1 Demand Forecast & M2 Replenishment Engine
-- Features: current_dos, stockout_days_last_90d, shrinkage_rate_90d, shelf_life_remaining_days
-- Reference: inventory_fulfilment_data_model_v1.md section 2.2

with latest_position as (
    select
        snapshot_date as as_of_date,
        sku_id,
        location_id,
        on_hand_qty,
        available_qty,
        days_of_supply as current_dos,
        inventory_value,
        stockout_risk_flag,
        row_number() over (partition by sku_id, location_id order by snapshot_date desc) as rn
    from {{ ref('fct_daily_inventory_position') }}
),

stockout_90d as (
    select
        sku_id,
        location_id,
        count(case when is_stockout = true then 1 else null end) as stockout_days_last_90d
    from {{ ref('fct_inventory_snapshots') }}
    where snapshot_date >= dateadd(day, -90, current_date())
    group by sku_id, location_id
),

shrinkage_90d as (
    select
        sku_id,
        location_id,
        round(
            abs(sum(case when movement_type in ('ADJUSTMENT', 'WRITE_OFF') and quantity < 0 then quantity else 0 end))
            / nullif(sum(case when movement_type = 'RECEIPT' then quantity else 0 end), 0),
            4
        ) as shrinkage_rate_90d
    from {{ ref('fct_inventory_movements') }}
    where movement_timestamp >= dateadd(day, -90, current_timestamp())
    group by sku_id, location_id
)

select
    lp.as_of_date,
    lp.sku_id,
    lp.location_id,
    p.product_name,
    p.category,
    p.abc_class,
    lp.on_hand_qty,
    lp.available_qty,
    lp.current_dos,
    coalesce(so.stockout_days_last_90d, 0) as stockout_days_last_90d,
    coalesce(sh.shrinkage_rate_90d, 0.0000) as shrinkage_rate_90d,
    coalesce(p.shelf_life_days, 365) as shelf_life_remaining_days,
    lp.inventory_value,
    lp.stockout_risk_flag
from latest_position as lp
left join stockout_90d as so
    on lp.sku_id = so.sku_id
   and lp.location_id = so.location_id
left join shrinkage_90d as sh
    on lp.sku_id = sh.sku_id
   and lp.location_id = sh.location_id
left join {{ ref('dim_products') }} as p
    on lp.sku_id = p.sku_id
where lp.rn = 1
