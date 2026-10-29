create database if not exists retail_intelligence_dev;
use database retail_intelligence_dev;

create schema if not exists raw;
create schema if not exists bronze;
create schema if not exists silver;
create schema if not exists gold;
create schema if not exists ML;

create stage if not exists raw.ingestion;

CREATE OR REPLACE FILE FORMAT raw.FF_JSON_RETAIL
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    IGNORE_UTF8_ERRORS = FALSE
    ALLOW_DUPLICATE = FALSE
    STRIP_NULL_VALUES = FALSE;

CREATE OR REPLACE TABLE raw.product_catalog_raw (
    raw_payload             VARIANT,
    source_file_name         VARCHAR(500),
    ingestion_timestamp      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

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



