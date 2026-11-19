-- Consolidated validation test for promotions
-- Covers: composite PK nulls, duplicates, discount percentage limits, date chronology, foreign key to products

with duplicates as (
    select promo_id, sku_id
    from {{ ref('promotions') }}
    where promo_id is not null and sku_id is not null
    group by promo_id, sku_id
    having count(*) > 1
),
valid_products as (
    select sku_id from {{ ref('products') }} where sku_id is not null
)

select
    p.promo_id,
    p.sku_id,
    p.promo_type,
    p.discount_pct,
    p.start_date,
    p.end_date,
    p.promo_status,
    case
        when p.promo_id is null or p.sku_id is null then 'Missing composite primary key components'
        when d.sku_id is not null then 'Duplicate promo_id and sku_id'
        when p.promo_type is null then 'Missing promo_type'
        when p.discount_pct is null or p.discount_pct <= 0 or p.discount_pct > 100 then 'Invalid discount percentage (must be between 1 and 100)'
        when p.start_date is null or p.end_date is null then 'Missing promotion date range'
        when p.end_date < p.start_date then 'Chronology violation: end_date precedes start_date'
        when vp.sku_id is null then 'Foreign key violation: sku_id does not exist in products'
        else 'Promotions validation failure'
    end as failure_reason
from {{ ref('promotions') }} as p
left join duplicates as d
    on p.promo_id = d.promo_id and p.sku_id = d.sku_id
left join valid_products as vp
    on p.sku_id = vp.sku_id
where p.promo_id is null
   or p.sku_id is null
   or d.sku_id is not null
   or p.promo_type is null
   or p.discount_pct is null
   or p.discount_pct <= 0
   or p.discount_pct > 100
   or p.start_date is null
   or p.end_date is null
   or p.end_date < p.start_date
   or vp.sku_id is null
