-- Consolidated validation test for sales_demand
-- Covers: composite PK nulls, duplicates, valid channel, negative sales/returns, foreign keys to products and locations

with duplicates as (
    select sales_date, sku_id, location_id, channel
    from {{ ref('sales_demand') }}
    where sales_date is not null
      and sku_id is not null
      and location_id is not null
      and channel is not null
    group by sales_date, sku_id, location_id, channel
    having count(*) > 1
),
valid_products as (
    select sku_id from {{ ref('products') }} where sku_id is not null
),
valid_locations as (
    select location_id from {{ ref('locations') }} where location_id is not null
)

select
    s.sales_date,
    s.sku_id,
    s.location_id,
    s.channel,
    s.units_sold,
    s.sales_amount,
    s.avg_selling_price,
    s.units_returned,
    case
        when s.sales_date is null or s.sku_id is null or s.location_id is null or s.channel is null then 'Missing composite primary key components'
        when d.sku_id is not null then 'Duplicate sales_demand composite key'
        when s.channel not in ('IN_STORE', 'WEB', 'APP') then 'Invalid sales channel'
        when s.units_sold is null or s.units_sold < 0 then 'Invalid units_sold (null or negative)'
        when s.sales_amount is null or s.sales_amount < 0 then 'Invalid sales_amount (null or negative)'
        when s.avg_selling_price is null or s.avg_selling_price < 0 then 'Invalid avg_selling_price (null or negative)'
        when s.units_returned < 0 then 'Negative units_returned'
        when vp.sku_id is null then 'Foreign key violation: sku_id does not exist in products'
        when vl.location_id is null then 'Foreign key violation: location_id does not exist in locations'
        else 'Sales demand validation failure'
    end as failure_reason
from {{ ref('sales_demand') }} as s
left join duplicates as d
    on s.sales_date = d.sales_date
   and s.sku_id = d.sku_id
   and s.location_id = d.location_id
   and s.channel = d.channel
left join valid_products as vp
    on s.sku_id = vp.sku_id
left join valid_locations as vl
    on s.location_id = vl.location_id
where s.sales_date is null
   or s.sku_id is null
   or s.location_id is null
   or s.channel is null
   or d.sku_id is not null
   or s.channel not in ('IN_STORE', 'WEB', 'APP')
   or s.units_sold is null
   or s.units_sold < 0
   or s.sales_amount is null
   or s.sales_amount < 0
   or s.avg_selling_price is null
   or s.avg_selling_price < 0
   or s.units_returned < 0
   or vp.sku_id is null
   or vl.location_id is null
