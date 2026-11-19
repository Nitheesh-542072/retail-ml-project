-- Consolidated validation test for customer_orders
-- Covers: composite PK nulls, duplicates, positive quantities and prices, promised delivery date, status, service levels, foreign keys

with duplicates as (
    select order_id, sku_id
    from {{ ref('customer_orders') }}
    where order_id is not null and sku_id is not null
    group by order_id, sku_id
    having count(*) > 1
),
valid_products as (
    select sku_id from {{ ref('products') }} where sku_id is not null
),
valid_locations as (
    select location_id from {{ ref('locations') }} where location_id is not null
)

select
    co.order_id,
    co.sku_id,
    co.customer_id,
    co.fulfilled_from_location_id,
    co.qty,
    co.unit_price,
    co.order_timestamp,
    co.promised_delivery_date,
    co.service_level,
    co.order_status,
    case
        when co.order_id is null or co.sku_id is null then 'Missing composite primary key components'
        when d.sku_id is not null then 'Duplicate order_id and sku_id'
        when co.customer_id is null then 'Missing customer_id'
        when co.fulfilled_from_location_id is null then 'Missing fulfilled_from_location_id'
        when co.qty is null or co.qty <= 0 then 'Invalid order line quantity (must be > 0)'
        when co.unit_price is null or co.unit_price <= 0 then 'Invalid unit_price (must be > 0)'
        when co.order_timestamp is null then 'Missing order_timestamp'
        when co.promised_delivery_date is null then 'Missing promised_delivery_date'
        when co.promised_delivery_date < co.order_timestamp::date then 'Promised delivery date cannot precede order date'
        when co.service_level not in ('SAME_DAY', 'NEXT_DAY', 'STANDARD') then 'Invalid delivery service_level'
        when co.order_status not in ('DELIVERED', 'SHIPPED', 'PACKED', 'CREATED', 'CANCELLED') then 'Invalid order_status'
        when vp.sku_id is null then 'Foreign key violation: sku_id does not exist in products'
        when vl.location_id is null then 'Foreign key violation: fulfilled_from_location_id does not exist in locations'
        else 'Customer order validation failure'
    end as failure_reason
from {{ ref('customer_orders') }} as co
left join duplicates as d
    on co.order_id = d.order_id and co.sku_id = d.sku_id
left join valid_products as vp
    on co.sku_id = vp.sku_id
left join valid_locations as vl
    on co.fulfilled_from_location_id = vl.location_id
where co.order_id is null
   or co.sku_id is null
   or d.sku_id is not null
   or co.customer_id is null
   or co.fulfilled_from_location_id is null
   or co.qty is null
   or co.qty <= 0
   or co.unit_price is null
   or co.unit_price <= 0
   or co.order_timestamp is null
   or co.promised_delivery_date is null
   or co.promised_delivery_date < co.order_timestamp::date
   or co.service_level not in ('SAME_DAY', 'NEXT_DAY', 'STANDARD')
   or co.order_status not in ('DELIVERED', 'SHIPPED', 'PACKED', 'CREATED', 'CANCELLED')
   or vp.sku_id is null
   or vl.location_id is null
