
USE ROLE dev_ops_role;
USE WAREHOUSE MY_WH;


CREATE OR REPLACE PROCEDURE common.identify_new_data()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
    INSERT INTO common.data_to_process (event_id, event_timestamp, process_name, process_id, message)
    (SELECT event_id, event_timestamp, process_name, process_id, message FROM common.raw_events_stream);
$$;

-- -------------

CREATE OR REPLACE PROCEDURE common.log_results(graph_run_group_id STRING, table_name STRING, n_rows NUMBER,error_message STRING)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
    INSERT INTO common.logging (graph_run_group_id, table_name, n_rows, error_message)
    VALUES (:graph_run_group_id, :table_name, :n_rows, :error_message);
$$;


CREATE OR REPLACE PROCEDURE common.data_quality(graph_run_group_id STRING)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
    LET nbre_lignes_incorrectes INT := 0;

    INSERT INTO common.data_anomalies (event_id, is_correct_timestamp, is_correct_process_name, graph_run_group_id)
    WITH source AS (
        SELECT
            event_id,
            common.check_correct_timestamp(event_timestamp)  AS is_correct_timestamp,
            common.check_correct_process_name(process_name)  AS is_correct_process_name
        FROM raw.raw_events
    )
    SELECT *, :graph_run_group_id AS graph_run_group_id
    FROM source
    WHERE is_correct_timestamp = FALSE OR is_correct_process_name = FALSE;

    nbre_lignes_incorrectes := SQLROWCOUNT;

    RETURN :nbre_lignes_incorrectes;
END;
$$;


CREATE OR REPLACE PROCEDURE common.arrivees_tardives(graph_run_group_id STRING)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
    LET n_late INT := 0;

    -- Insérer dans data_anomalies les événements arrivés avec + de 5 jours de retard
    -- qui ne sont pas déjà enregistrés comme anomalies
    INSERT INTO common.data_anomalies (
        event_id,
        is_correct_timestamp,
        is_correct_process_name,
        is_late_arrival,
        graph_run_group_id
    )
    SELECT
        dtp.event_id,
        TRUE AS is_correct_timestamp,
        TRUE AS is_correct_process_name,
        TRUE AS is_late_arrival,
        :graph_run_group_id AS graph_run_group_id
    FROM common.data_to_process dtp
    JOIN raw.raw_events re
        ON dtp.event_id = re.event_id
    LEFT JOIN common.data_anomalies da
        ON dtp.event_id = da.event_id
    WHERE common.check_late_arrival(re.event_timestamp)
      AND da.event_id IS NULL;  -- pas encore marqué comme anomalie

    n_late := SQLROWCOUNT;

    -- Logger le résultat
    CALL common.log_results(:graph_run_group_id, 'arrivees_tardives',:n_late, NULL);
    RETURN :n_late || ' arrivées tardives détectées et exclues';
END;
$$;


-- ---------------

CREATE OR REPLACE PROCEDURE common.ENRICH_DATA( TABLE_NAME STRING, PROCESS_NAME STRING, GRAPH_RUN_GROUP_ID STRING)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    full_table_name    STRING    := CONCAT('staging.', :table_name);
    insert_exception   EXCEPTION (-20001, 'Exception in data loading into staging tables');

BEGIN
    LET n_rows INT := 0;

    INSERT INTO IDENTIFIER(:full_table_name) (event_timestamp, process_id, log_trigger, message)
    WITH source AS
        (
            SELECT
                re.event_timestamp,
                re.process_name,
                re.process_id,
                common.extract_log_trigger(re.message) AS log_trigger,
                common.extract_log_message(re.message) AS message
            FROM raw.raw_events re
            JOIN common.data_to_process dtp
                ON re.event_id = dtp.event_id
            LEFT JOIN common.data_anomalies da
                ON re.event_id = da.event_id
            WHERE re.process_name = :process_name
              AND da.event_id IS NULL
        )
     SELECT
        event_timestamp,
        process_id,
        log_trigger,
        message
    FROM source;
    n_rows := SQLROWCOUNT;
    CALL common.log_results(:graph_run_group_id, :table_name, :n_rows,NULL);
    EXCEPTION
        WHEN OTHER THEN
            CALL common.log_results(:graph_run_group_id, :table_name,NULL, :SQLERRM);
    RETURN :n_rows;
END;
$$;



-- --------------------------

CREATE OR REPLACE PROCEDURE common.finalize_transformation(graph_run_group_id STRING,started_at TIMESTAMP)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    pipeline_exception EXCEPTION (-20002,'Exception in the transformation pipeline');
BEGIN
    LET n_errors INT := 0;

    SELECT COUNT(*) INTO n_errors
    FROM common.logging
    WHERE graph_run_group_id = :graph_run_group_id
      AND error_message IS NOT NULL;

    INSERT INTO common.transformation_pipeline_status (graph_run_group_id, started_at, finished_at, status)
    SELECT
        :graph_run_group_id AS graph_run_group_id,
        :started_at         AS started_at,
        CURRENT_TIMESTAMP() AS finished_at,
        IFF(:n_errors > 0, 'FAILED', 'SUCCEEDED');
    IF (n_errors = 0) THEN
        TRUNCATE TABLE common.data_to_process;
    ELSE 
        RAISE pipeline_exception;
    END IF;

END;
$$;
