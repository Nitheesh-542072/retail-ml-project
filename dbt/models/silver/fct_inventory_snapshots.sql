{{ config(
    materialized = 'incremental',
    unique_key = ['snapshot_date', 'sku_id', 'location_id']
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='test_inventory_snapshots') %}

select
    b.snapshot_date,
    b.sku_id,
    b.location_id,
    b.on_hand_qty,
    b.reserved_qty,
    b.available_qty,
    b.in_transit_qty,
    b.damaged_qty,
    b.safety_stock_qty,
    b.is_stockout,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('inventory_snapshots') }} as b
{% if err_table %}
left join {{ err_table }} as err
    on b.snapshot_date = err.snapshot_date
   and b.sku_id = err.sku_id
   and b.location_id = err.location_id
{% endif %}
where 1 = 1
{% if err_table %}
  and err.sku_id is null
{% endif %}
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
