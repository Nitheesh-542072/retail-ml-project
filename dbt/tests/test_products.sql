-- Consolidated validation test for products
-- Covers: null PK, duplicates, pricing logic, valid categories, valid status and tiers

with duplicates as (
    select sku_id
    from {{ ref('products') }}
    where sku_id is not null
    group by sku_id
    having count(*) > 1
)

select
    p.sku_id,
    p.product_name,
    p.unit_cost,
    p.unit_price,
    case
        when p.sku_id is null then 'Missing primary key sku_id'
        when d.sku_id is not null then 'Duplicate sku_id'
        when p.product_name is null then 'Missing product_name'
        when p.category is null then 'Missing category'
        when p.abc_class not in ('A', 'B', 'C') then 'Invalid abc_class tier'
        when p.status not in ('NEW', 'ACTIVE', 'DISCONTINUED') then 'Invalid product status'
        when p.unit_cost <= 0 or p.unit_price <= 0 then 'Non-positive pricing (cost or price <= 0)'
        when p.unit_price <= p.unit_cost then 'Unit price must be strictly greater than wholesale cost'
        else 'Product validation failure'
    end as failure_reason
from {{ ref('products') }} as p
left join duplicates as d
    on p.sku_id = d.sku_id
where p.sku_id is null
   or d.sku_id is not null
   or p.product_name is null
   or p.category is null
   or p.abc_class not in ('A', 'B', 'C')
   or p.status not in ('NEW', 'ACTIVE', 'DISCONTINUED')
   or p.unit_cost <= 0
   or p.unit_price <= 0
   or p.unit_price <= p.unit_cost
