{{ config(
    materialized = 'incremental',
    unique_key = 'transfer_id'
) }}

{% set err_table = adapter.get_relation(database=target.database, schema='ERROR', identifier='assert_transfer_locations_different') %}

select
    b.transfer_id,
    b.from_location_id,
    b.to_location_id,
    b.sku_id,
    b.qty,
    b.shipped_date,
    b.received_date,
    b.status,
    b.source_file_name,
    b.ingestion_timestamp
from {{ ref('transfers') }} as b
{% if err_table %}
left join {{ err_table }} as err
    on b.transfer_id = err.transfer_id
where err.transfer_id is null
{% if is_incremental() %}
  and b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
{% else %}
{% if is_incremental() %}
where b.ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
{% endif %}
