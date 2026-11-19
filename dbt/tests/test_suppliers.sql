-- Consolidated validation test for suppliers
-- Covers: null PKs, duplicates, positive lead times, MOQs, unit costs, foreign keys to products

with duplicates as (
    select supplier_id, sku_id
    from {{ ref('suppliers') }}
    where supplier_id is not null and sku_id is not null
    group by supplier_id, sku_id
    having count(*) > 1
),
valid_products as (
    select sku_id from {{ ref('products') }} where sku_id is not null
)

select
    s.supplier_id,
    s.sku_id,
    s.supplier_name,
    case
        when s.supplier_id is null or s.sku_id is null then 'Missing supplier_id or sku_id'
        when d.supplier_id is not null then 'Duplicate composite key (supplier_id, sku_id)'
        when s.supplier_name is null then 'Missing supplier_name'
        when s.promised_lead_time_days <= 0 then 'Non-positive promised lead time'
        when s.moq <= 0 then 'Non-positive MOQ'
        when s.contract_unit_cost < 0 then 'Negative contract unit cost'
        when vp.sku_id is null then 'Foreign key violation: sku_id does not exist in products'
        else 'Supplier validation failure'
    end as failure_reason
from {{ ref('suppliers') }} as s
left join duplicates as d
    on s.supplier_id = d.supplier_id and s.sku_id = d.sku_id
left join valid_products as vp
    on s.sku_id = vp.sku_id
where s.supplier_id is null
   or s.sku_id is null
   or d.supplier_id is not null
   or s.supplier_name is null
   or s.promised_lead_time_days <= 0
   or s.moq <= 0
   or s.contract_unit_cost < 0
   or vp.sku_id is null
