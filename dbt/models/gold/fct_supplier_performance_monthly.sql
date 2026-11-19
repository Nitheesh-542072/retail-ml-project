{{ config(
    materialized = 'table',
    unique_key = ['month_start_date', 'supplier_id', 'sku_id']
) }}

-- Curated gold fact: monthly vendor scorecards
-- Metrics: average actual lead time, lead-time variance, fill rate %, OTIF %
-- Reference: inventory_fulfilment_data_model_v1.md section 2.2

with po_metrics as (
    select
        date_trunc('month', po.order_date)::date as month_start_date,
        po.supplier_id,
        po.sku_id,
        po.po_id,
        po.ordered_qty,
        po.received_qty,
        po.status,
        po.order_date,
        po.expected_delivery_date,
        po.actual_delivery_date,
        datediff(day, po.order_date, po.expected_delivery_date) as expected_lead_time_days,
        case
            when po.actual_delivery_date is not null
                then datediff(day, po.order_date, po.actual_delivery_date)
            else null
        end as actual_lead_time_days,
        case
            when po.actual_delivery_date is not null and po.actual_delivery_date <= po.expected_delivery_date
                then 1
            else 0
        end as is_on_time,
        case
            when coalesce(po.received_qty, 0) >= po.ordered_qty
                then 1
            else 0
        end as is_in_full,
        case
            when po.actual_delivery_date is not null
             and po.actual_delivery_date <= po.expected_delivery_date
             and coalesce(po.received_qty, 0) >= po.ordered_qty
                then 1
            else 0
        end as is_otif
    from {{ ref('fct_purchase_orders') }} as po
)

select
    m.month_start_date,
    m.supplier_id,
    m.sku_id,
    s.supplier_name,
    s.country as supplier_country,
    p.product_name,
    p.category,
    terms.contracted_lead_time_days,
    terms.moq,
    terms.contract_unit_cost,
    count(distinct m.po_id) as total_pos_placed,
    count(case when m.status = 'RECEIVED' then 1 else null end) as total_pos_received,
    sum(m.ordered_qty) as total_ordered_qty,
    sum(coalesce(m.received_qty, 0)) as total_received_qty,
    round(avg(m.expected_lead_time_days), 2) as avg_expected_lead_time_days,
    round(avg(m.actual_lead_time_days), 2) as avg_actual_lead_time_days,
    round(coalesce(stddev(m.actual_lead_time_days), 0), 2) as lead_time_variance_days,
    round(avg(m.actual_lead_time_days) - avg(m.expected_lead_time_days), 2) as avg_lead_time_delay_days,
    round(100.0 * sum(coalesce(m.received_qty, 0)) / nullif(sum(m.ordered_qty), 0), 2) as fill_rate_pct,
    round(100.0 * sum(case when m.status = 'RECEIVED' then m.is_on_time else 0 end) / nullif(count(case when m.status = 'RECEIVED' then 1 else null end), 0), 2) as on_time_pct,
    round(100.0 * sum(case when m.status = 'RECEIVED' then m.is_in_full else 0 end) / nullif(count(case when m.status = 'RECEIVED' then 1 else null end), 0), 2) as in_full_pct,
    round(100.0 * sum(case when m.status = 'RECEIVED' then m.is_otif else 0 end) / nullif(count(case when m.status = 'RECEIVED' then 1 else null end), 0), 2) as otif_pct
from po_metrics as m
left join {{ ref('dim_suppliers') }} as s
    on m.supplier_id = s.supplier_id
left join {{ ref('dim_products') }} as p
    on m.sku_id = p.sku_id
left join {{ ref('dim_supplier_sku_terms') }} as terms
    on m.supplier_id = terms.supplier_id
   and m.sku_id = terms.sku_id
group by
    m.month_start_date,
    m.supplier_id,
    m.sku_id,
    s.supplier_name,
    s.country,
    p.product_name,
    p.category,
    terms.contracted_lead_time_days,
    terms.moq,
    terms.contract_unit_cost
