{{ config(
    materialized = 'view'
) }}

-- Feature View: FV_SUPPLIER_RELIABILITY
-- Used by M2 Replenishment Engine & Lead-Time Prediction
-- Features: contracted_lead_time_days, historical_lead_time_p50, historical_lead_time_p90, supplier_otif_rate_90d
-- Reference: inventory_fulfilment_data_model_v1.md section 2.2

with po_90d as (
    select
        supplier_id,
        sku_id,
        datediff(day, order_date, actual_delivery_date) as actual_lead_time_days,
        case
            when actual_delivery_date <= expected_delivery_date and coalesce(received_qty, 0) >= ordered_qty
                then 1
            else 0
        end as is_otif
    from {{ ref('fct_purchase_orders') }}
    where status = 'RECEIVED'
      and actual_delivery_date is not null
      and order_date >= dateadd(day, -90, current_date())
),

lead_time_stats as (
    select
        supplier_id,
        sku_id,
        count(*) as total_received_pos_90d,
        round(percentile_cont(0.50) within group (order by actual_lead_time_days), 1) as historical_lead_time_p50,
        round(percentile_cont(0.90) within group (order by actual_lead_time_days), 1) as historical_lead_time_p90,
        round(100.0 * sum(is_otif) / nullif(count(*), 0), 2) as supplier_otif_rate_90d
    from po_90d
    group by supplier_id, sku_id
)

select
    t.supplier_id,
    t.sku_id,
    s.supplier_name,
    s.country as supplier_country,
    p.product_name,
    p.category,
    t.contracted_lead_time_days,
    t.moq,
    t.contract_unit_cost,
    t.is_preferred,
    coalesce(lts.total_received_pos_90d, 0) as sample_size_pos_90d,
    coalesce(lts.historical_lead_time_p50, t.contracted_lead_time_days::float) as historical_lead_time_p50,
    coalesce(lts.historical_lead_time_p90, (t.contracted_lead_time_days * 1.3)::float) as historical_lead_time_p90,
    coalesce(lts.supplier_otif_rate_90d, 100.0) as supplier_otif_rate_90d
from {{ ref('dim_supplier_sku_terms') }} as t
left join lead_time_stats as lts
    on t.supplier_id = lts.supplier_id
   and t.sku_id = lts.sku_id
left join {{ ref('dim_suppliers') }} as s
    on t.supplier_id = s.supplier_id
left join {{ ref('dim_products') }} as p
    on t.sku_id = p.sku_id
