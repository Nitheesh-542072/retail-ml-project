{{ config(
    materialized = 'table',
    unique_key = ['sales_date', 'sku_id', 'location_id']
) }}

-- Curated gold fact: daily channel-aggregated demand with promo flags and estimated lost sales
-- Reference: inventory_fulfilment_data_model_v1.md section 2.2

with channel_demand as (
    select
        sales_date,
        sku_id,
        location_id,
        sum(units_sold) as total_units_sold,
        sum(sales_amount) as total_sales_amount,
        sum(units_returned) as total_units_returned,
        sum(units_sold) - sum(units_returned) as net_units_sold,
        sum(case when channel = 'IN_STORE' then units_sold else 0 end) as store_units_sold,
        sum(case when channel = 'WEB' then units_sold else 0 end) as web_units_sold,
        sum(case when channel = 'APP' then units_sold else 0 end) as app_units_sold,
        round(avg(avg_selling_price), 2) as realized_avg_selling_price
    from {{ ref('fct_sales_demand') }}
    group by sales_date, sku_id, location_id
),

active_promos as (
    select
        sku_id,
        start_date,
        end_date,
        promo_type,
        max(discount_pct) as max_discount_pct
    from {{ ref('fct_promotions') }}
    group by sku_id, start_date, end_date, promo_type
),

stockout_status as (
    select
        snapshot_date,
        sku_id,
        location_id,
        is_stockout,
        available_qty
    from {{ ref('fct_inventory_snapshots') }}
),

daily_joined as (
    select
        cd.sales_date,
        cd.sku_id,
        cd.location_id,
        cd.total_units_sold,
        cd.total_sales_amount,
        cd.total_units_returned,
        cd.net_units_sold,
        cd.store_units_sold,
        cd.web_units_sold,
        cd.app_units_sold,
        cd.realized_avg_selling_price,
        coalesce(st.is_stockout, false) as is_stockout,
        st.available_qty,
        case when pr.sku_id is not null then true else false end as is_promo_active,
        coalesce(pr.max_discount_pct, 0) as promo_discount_pct,
        pr.promo_type,
        cal.is_holiday,
        cal.holiday_name,
        cal.is_peak_period,
        cal.fiscal_week,
        cal.fiscal_month,
        p.product_name,
        p.category,
        p.abc_class,
        p.unit_price,
        p.unit_cost,
        l.location_type,
        l.region
    from channel_demand as cd
    left join stockout_status as st
        on cd.sales_date = st.snapshot_date
       and cd.sku_id = st.sku_id
       and cd.location_id = st.location_id
    left join active_promos as pr
        on cd.sku_id = pr.sku_id
       and cd.sales_date between pr.start_date and pr.end_date
    left join {{ ref('dim_calendar') }} as cal
        on cd.sales_date = cal.calendar_date
    left join {{ ref('dim_products') }} as p
        on cd.sku_id = p.sku_id
    left join {{ ref('dim_locations') }} as l
        on cd.location_id = l.location_id
),

with_lost_sales as (
    select
        dj.*,
        avg(case when dj.is_stockout = false then dj.total_units_sold else null end) over (
            partition by dj.sku_id, dj.location_id 
            order by dj.sales_date 
            rows between 14 preceding and 1 preceding
        ) as baseline_daily_sales
    from daily_joined as dj
)

select
    sales_date,
    sku_id,
    location_id,
    product_name,
    category,
    abc_class,
    location_type,
    region,
    total_units_sold,
    total_sales_amount,
    total_units_returned,
    net_units_sold,
    store_units_sold,
    web_units_sold,
    app_units_sold,
    realized_avg_selling_price,
    is_promo_active,
    promo_discount_pct,
    promo_type,
    is_holiday,
    holiday_name,
    is_peak_period,
    fiscal_week,
    fiscal_month,
    is_stockout,
    available_qty,
    case
        when is_stockout = true and baseline_daily_sales > total_units_sold
            then round(baseline_daily_sales - total_units_sold, 0)::integer
        else 0
    end as estimated_lost_sales_units,
    case
        when is_stockout = true and baseline_daily_sales > total_units_sold
            then round((baseline_daily_sales - total_units_sold) * coalesce(unit_price, 0), 2)
        else 0.00
    end as estimated_lost_sales_amount
from with_lost_sales
