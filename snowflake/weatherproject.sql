-- 1. Create and select database
CREATE DATABASE IF NOT EXISTS WEATHER_DB;
USE DATABASE WEATHER_DB;
USE SCHEMA PUBLIC;
USE ROLE ACCOUNTADMIN;

-- 2. Create Storage Integration
CREATE OR REPLACE STORAGE INTEGRATION s3_int
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::876178094600:role/snowflake_s3_role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://weather-bucket003/');

    DESC INTEGRATION s3_int;

-- 3. Create Stage
CREATE OR REPLACE STAGE weather_stage
    URL = 's3://weather-bucket003/'
    STORAGE_INTEGRATION = s3_int
    FILE_FORMAT = (TYPE = 'JSON');

-- 4. Define file format
CREATE OR REPLACE FILE FORMAT json_format
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = FALSE
    IGNORE_UTF8_ERRORS = TRUE;

-- 5. Create table
CREATE OR REPLACE TABLE weather_data (
    city        VARCHAR(100),
    temperature FLOAT,
    humidity    INT,
    weather     VARCHAR(100),
    time        VARCHAR(50)
);

-- 6. CREATE PIPE
COPY INTO weather_data
FROM (
    SELECT
        $1:city::STRING,
        $1:temperature::FLOAT,
        $1:humidity::INT,
        $1:weather::STRING,
        $1:time::STRING
    FROM @weather_stage
    (FILE_FORMAT => json_format,
     PATTERN => 'weather_202605[0-9]{2}_[0-9]{6}\\.json')  
)
ON_ERROR = SKIP_FILE;


-- 7. Check files in S3
LIST @weather_stage PATTERN='.*weather_[0-9]+.*\\.json';


-- 8. Clean table before loading
TRUNCATE TABLE weather_data;


-- 9. Verify clean data
SELECT * FROM weather_data ORDER BY time DESC LIMIT 20;



