-- ==============================================================================
-- Inventory & Fulfilment Platform: Database, Schemas, Tables & Ingestion
-- Target Database: retail_intelligence_dev
-- Workload: M1 (Demand & Stock-out), M2 (Replenishment), M3 (Late Delivery & Sourcing)
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS retail_intelligence_dev;
USE DATABASE retail_intelligence_dev;

-- 1. Core Schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS test_failures
    COMMENT = 'Dedicated schema for dbt store_failures audit tables (captures failing rows from DQ tests)';
CREATE SCHEMA IF NOT EXISTS dbt_test__audit
    COMMENT = 'Default dbt audit schema fallback for store_failures';

-- 2. Internal Stage
CREATE STAGE IF NOT EXISTS raw.INT_STG_INVENTORY_FULFILMENT
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- 3. File Formats
CREATE OR REPLACE FILE FORMAT raw.FF_CSV_INVENTORY
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

CREATE OR REPLACE FILE FORMAT raw.FF_JSON_INVENTORY
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    IGNORE_UTF8_ERRORS = FALSE
    ALLOW_DUPLICATE = FALSE
    STRIP_NULL_VALUES = FALSE;

-- ==============================================================================
-- SECTION A: Structured Raw Tables (9 CSV Datasets)
-- ==============================================================================

-- 1. Products Raw
CREATE OR REPLACE TABLE raw.products_raw (
    sku_id VARCHAR(50),
    product_name VARCHAR(255),
    category VARCHAR(100),
    brand VARCHAR(100),
    abc_class VARCHAR(10),
    unit_cost VARCHAR(20),
    unit_price VARCHAR(20),
    case_pack_qty VARCHAR(20),
    weight_kg VARCHAR(20),
    shelf_life_days VARCHAR(20),
    status VARCHAR(50),
    launch_date VARCHAR(20),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 2. Locations Raw
CREATE OR REPLACE TABLE raw.locations_raw (
    location_id VARCHAR(50),
    location_type VARCHAR(50),
    region VARCHAR(50),
    postal_code VARCHAR(20),
    latitude VARCHAR(30),
    longitude VARCHAR(30),
    parent_dc_id VARCHAR(50),
    storage_capacity VARCHAR(30),
    daily_order_capacity VARCHAR(30),
    cutoff_time VARCHAR(20),
    is_active VARCHAR(10),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 3. Suppliers Raw
CREATE OR REPLACE TABLE raw.suppliers_raw (
    supplier_id VARCHAR(50),
    supplier_name VARCHAR(255),
    country VARCHAR(100),
    promised_lead_time_days VARCHAR(20),
    sku_id VARCHAR(50),
    moq VARCHAR(20),
    contract_unit_cost VARCHAR(20),
    is_preferred VARCHAR(10),
    is_active VARCHAR(10),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 4. Carriers Raw
CREATE OR REPLACE TABLE raw.carriers_raw (
    carrier_id VARCHAR(50),
    carrier_name VARCHAR(255),
    service_level VARCHAR(50),
    promised_transit_days VARCHAR(20),
    base_rate VARCHAR(20),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 5. Calendar Raw
CREATE OR REPLACE TABLE raw.calendar_raw (
    date VARCHAR(20),
    is_holiday VARCHAR(10),
    holiday_name VARCHAR(100),
    week VARCHAR(10),
    month VARCHAR(10),
    season VARCHAR(20),
    is_peak_period VARCHAR(10),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 6. Daily Stock Levels (Inventory Snapshots Raw)
CREATE OR REPLACE TABLE raw.inventory_snapshots_raw (
    snapshot_date VARCHAR(20),
    sku_id VARCHAR(50),
    location_id VARCHAR(50),
    on_hand_qty VARCHAR(20),
    reserved_qty VARCHAR(20),
    available_qty VARCHAR(20),
    in_transit_qty VARCHAR(20),
    damaged_qty VARCHAR(20),
    safety_stock_qty VARCHAR(20),
    is_stockout VARCHAR(10),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 7. Stock Movements Raw
CREATE OR REPLACE TABLE raw.inventory_movements_raw (
    movement_id VARCHAR(50),
    sku_id VARCHAR(50),
    location_id VARCHAR(50),
    movement_type VARCHAR(50),
    quantity VARCHAR(20),
    reference_id VARCHAR(50),
    reason_code VARCHAR(50),
    timestamp VARCHAR(30),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 8. Daily Sales Demand Raw
CREATE OR REPLACE TABLE raw.sales_demand_raw (
    sales_date VARCHAR(20),
    sku_id VARCHAR(50),
    location_id VARCHAR(50),
    channel VARCHAR(50),
    units_sold VARCHAR(20),
    sales_amount VARCHAR(20),
    avg_selling_price VARCHAR(20),
    units_returned VARCHAR(20),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 9. Stock Transfers Raw
CREATE OR REPLACE TABLE raw.transfers_raw (
    transfer_id VARCHAR(50),
    from_location_id VARCHAR(50),
    to_location_id VARCHAR(50),
    sku_id VARCHAR(50),
    qty VARCHAR(20),
    shipped_date VARCHAR(20),
    received_date VARCHAR(20),
    status VARCHAR(50),
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ==============================================================================
-- SECTION B: Semi-Structured Raw Tables (4 JSON Datasets)
-- ==============================================================================

-- 10. Promotions Raw
CREATE OR REPLACE TABLE raw.promotions_raw (
    raw_payload VARIANT,
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 11. Purchase Orders Raw
CREATE OR REPLACE TABLE raw.purchase_orders_raw (
    raw_payload VARIANT,
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 12. Customer Orders Raw
CREATE OR REPLACE TABLE raw.customer_orders_raw (
    raw_payload VARIANT,
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 13. Shipments Raw
CREATE OR REPLACE TABLE raw.shipments_raw (
    raw_payload VARIANT,
    source_file_name VARCHAR(500),
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ==============================================================================
-- SECTION C: COPY INTO Ingestion Scripts
-- ==============================================================================

-- 1. Load Products (CSV)
COPY INTO raw.products_raw (
    sku_id, product_name, category, brand, abc_class,
    unit_cost, unit_price, case_pack_qty, weight_kg,
    shelf_life_days, status, launch_date,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4, $5,
        $6, $7, $8, $9,
        $10, $11, $12,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/products.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 2. Load Locations (CSV)
COPY INTO raw.locations_raw (
    location_id, location_type, region, postal_code,
    latitude, longitude, parent_dc_id, storage_capacity,
    daily_order_capacity, cutoff_time, is_active,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4,
        $5, $6, $7, $8,
        $9, $10, $11,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/locations.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 3. Load Suppliers (CSV)
COPY INTO raw.suppliers_raw (
    supplier_id, supplier_name, country, promised_lead_time_days,
    sku_id, moq, contract_unit_cost, is_preferred, is_active,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4,
        $5, $6, $7, $8, $9,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/suppliers.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 4. Load Carriers (CSV)
COPY INTO raw.carriers_raw (
    carrier_id, carrier_name, service_level,
    promised_transit_days, base_rate,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4, $5,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/carriers.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 5. Load Calendar (CSV)
COPY INTO raw.calendar_raw (
    date, is_holiday, holiday_name, week, month, season, is_peak_period,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4, $5, $6, $7,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/calendar.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 6. Load Daily Stock Levels (CSV)
COPY INTO raw.inventory_snapshots_raw (
    snapshot_date, sku_id, location_id, on_hand_qty,
    reserved_qty, available_qty, in_transit_qty, damaged_qty,
    safety_stock_qty, is_stockout,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4,
        $5, $6, $7, $8,
        $9, $10,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/inventory_snapshots.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 7. Load Stock Movements (CSV)
COPY INTO raw.inventory_movements_raw (
    movement_id, sku_id, location_id, movement_type,
    quantity, reference_id, reason_code, timestamp,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4,
        $5, $6, $7, $8,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/inventory_movements.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 8. Load Daily Sales Demand (CSV)
COPY INTO raw.sales_demand_raw (
    sales_date, sku_id, location_id, channel,
    units_sold, sales_amount, avg_selling_price, units_returned,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4,
        $5, $6, $7, $8,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/sales_demand.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 9. Load Stock Transfers (CSV)
COPY INTO raw.transfers_raw (
    transfer_id, from_location_id, to_location_id, sku_id,
    qty, shipped_date, received_date, status,
    source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, $2, $3, $4,
        $5, $6, $7, $8,
        METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/transfers.csv
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_CSV_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 10. Load Promotions (JSON)
COPY INTO raw.promotions_raw (
    raw_payload, source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/promotions.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 11. Load Purchase Orders (JSON)
COPY INTO raw.purchase_orders_raw (
    raw_payload, source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/purchase_orders.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 12. Load Customer Orders (JSON)
COPY INTO raw.customer_orders_raw (
    raw_payload, source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/customer_orders.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- 13. Load Shipments (JSON)
COPY INTO raw.shipments_raw (
    raw_payload, source_file_name, ingestion_timestamp
)
FROM (
    SELECT
        $1, METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @raw.INT_STG_INVENTORY_FULFILMENT/shipments.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_INVENTORY')
ON_ERROR = 'ABORT_STATEMENT';

-- ==============================================================================
-- SECTION D: dbt store_failures Audit Tables (Automated by dbt)
-- ==============================================================================
-- NOTE: You do NOT need to create tables manually in test_failures schema!
-- When dbt runs with `store_failures: true`, dbt dynamically creates a table
-- in `retail_intelligence_dev.test_failures` whenever a test fails (e.g.):
--   - test_failures.unique_tbl_products_sku_id
--   - test_failures.assert_product_pricing_logic
--   - test_failures.not_null_tbl_locations_location_id
--
-- Querying failed rows:
--   SELECT * FROM retail_intelligence_dev.test_failures.<test_name>;
-- ==============================================================================
