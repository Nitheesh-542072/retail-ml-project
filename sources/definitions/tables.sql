
CREATE DATABASE IF NOT EXISTS retail_intelligence_dev;
USE DATABASE retail_intelligence_dev;

-- 1. Core Schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS ML;

-- 2. Internal Stage
CREATE STAGE IF NOT EXISTS raw.ingestion
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- 3. File Format 
CREATE OR REPLACE FILE FORMAT raw.FF_JSON_RETAIL
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    IGNORE_UTF8_ERRORS = FALSE
    ALLOW_DUPLICATE = FALSE
    STRIP_NULL_VALUES = FALSE;


-- Table 1: Product Catalog Raw
CREATE OR REPLACE TABLE raw.product_catalog_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Table 2: Customer Profiles Raw
CREATE OR REPLACE TABLE raw.customer_profiles_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Table 3: Inventory Levels Raw
CREATE OR REPLACE TABLE raw.inventory_levels_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Table 4: Transactions Raw
CREATE OR REPLACE TABLE raw.transactions_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Table 5: Campaigns Raw
CREATE OR REPLACE TABLE raw.campaigns_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Table 6: Campaign Interactions Raw
CREATE OR REPLACE TABLE raw.campaign_interactions_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Table 7: Channel Activities Raw
CREATE OR REPLACE TABLE raw.channel_activities_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Table 8: Cart Contexts Raw
CREATE OR REPLACE TABLE raw.cart_contexts_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Table 9: Support Tickets Raw
CREATE OR REPLACE TABLE raw.support_tickets_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


-- 1. Product Catalog 
COPY INTO raw.product_catalog_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/product_catalog.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';

-- 2. Customer Profiles 
COPY INTO raw.customer_profiles_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/customer_profiles.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';

-- 3. Inventory Levels 
COPY INTO raw.inventory_levels_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/inventory_levels.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';

-- 4. Transactions 
COPY INTO raw.transactions_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/transactions.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';

-- 5. Campaigns 
COPY INTO raw.campaigns_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/campaigns.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';

-- 6. Campaign Interactions 
COPY INTO raw.campaign_interactions_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/campaign_interactions.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';

-- 7. Channel Activities 
COPY INTO raw.channel_activities_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/channel_activities.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';

-- 8. Cart Contexts 
COPY INTO raw.cart_contexts_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/cart_contexts.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';

-- 9. Support Tickets 
COPY INTO raw.support_tickets_raw (
    raw_payload,
    source_file_name,
    ingestion_timestamp
)
FROM (
    SELECT 
        $1                  AS raw_payload,
        METADATA$FILENAME   AS source_file_name,
        CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM @raw.ingestion/support_tickets.json
)
FILE_FORMAT = (FORMAT_NAME = 'raw.FF_JSON_RETAIL')
ON_ERROR = 'ABORT_STATEMENT';
