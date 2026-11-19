{{ config(
    materialized = 'view'
) }}

-- Feature View: FV_SKU_LOCATION_DEMAND
-- Used by M1 Demand Forecasting Model
-- Features: sales_lag_7d, sales_lag_14d, sales_lag_28d, rolling_mean_7d, rolling_std_28d, promo_uplift_ratio, is_holiday
-- Reference: inventory_fulfilment_data_model_v1.md section 2.2

with demand_base as (
    select
        sales_date,
        sku_id,
        location_id,
        total_units_sold,
        is_promo_active,
        promo_discount_pct,
        is_holiday,
        is_peak_period
    from {{ ref('fct_daily_demand_summary') }}
),

windowed_features as (
    select
        sales_date,
        sku_id,
        location_id,
        total_units_sold,
        lag(total_units_sold, 7) over (
            partition by sku_id, location_id order by sales_date
        ) as sales_lag_7d,
        lag(total_units_sold, 14) over (
            partition by sku_id, location_id order by sales_date
        ) as sales_lag_14d,
        lag(total_units_sold, 28) over (
            partition by sku_id, location_id order by sales_date
        ) as sales_lag_28d,
        round(avg(total_units_sold) over (
            partition by sku_id, location_id order by sales_date rows between 6 preceding and current row
        ), 2) as rolling_mean_7d,
        round(avg(total_units_sold) over (
            partition by sku_id, location_id order by sales_date rows between 27 preceding and current row
        ), 2) as rolling_mean_28d,
        round(coalesce(stddev(total_units_sold) over (
            partition by sku_id, location_id order by sales_date rows between 27 preceding and current row
        ), 0), 2) as rolling_std_28d,
        is_promo_active,
        promo_discount_pct,
        is_holiday,
        is_peak_period
    from demand_base
)

select
    sales_date,
    sku_id,
    location_id,
    total_units_sold as actual_units_sold,
    coalesce(sales_lag_7d, 0) as sales_lag_7d,
    coalesce(sales_lag_14d, 0) as sales_lag_14d,
    coalesce(sales_lag_28d, 0) as sales_lag_28d,
    coalesce(rolling_mean_7d, total_units_sold) as rolling_mean_7d,
    coalesce(rolling_std_28d, 0.0) as rolling_std_28d,
    case
        when is_promo_active = true and coalesce(rolling_mean_28d, 0) > 0
            then round(total_units_sold / rolling_mean_28d, 3)
        else 1.000
    end as promo_uplift_ratio,
    is_holiday,
    is_peak_period
from windowed_features
