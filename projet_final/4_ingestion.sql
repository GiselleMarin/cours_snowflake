USE ROLE dev_ops_role;
 
CREATE OR ALTER FILE FORMAT raw.csv_file
TYPE=CSV
FIELD_DELIMITER='|'
TIMESTAMP_FORMAT='YYYYMMDD-HH24:MI:SS:FF3';

CREATE OR ALTER STAGE healt_app_projet.raw.internal_stage
FILE_FORMAT = raw.csv_file;


-- Création d'un pipe d'ingestion automatique

CREATE OR REPLACE PIPE raw.load_raw_data
  AUTO_INGEST = TRUE
  AS
   COPY INTO RAW.RAW_EVENTS (event_timestamp, process_name, process_id, message)
    FROM (
    SELECT
        TO_TIMESTAMP($1, 'YYYYMMDD-HH24:MI:SS:FF3') AS event_timestamp,
        $2                                           AS process_name,
        $3::NUMBER                                   AS process_id,
        $4                                           AS message
    FROM @RAW.internal_stage
        )
    FILE_FORMAT = RAW.csv_file;

