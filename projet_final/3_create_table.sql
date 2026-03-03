
USE ROLE dev_ops_role;

-- 1) creation des tables RAW:

-- 1) Remettre le event_id et recréer le stream
CREATE OR REPLACE TABLE raw.raw_events (
    event_id        NUMBER AUTOINCREMENT,
    event_timestamp TIMESTAMP,
    process_name    STRING,
    process_id      NUMBER,
    message         STRING

);

-- 1,1) creation des tables COMMON:

CREATE OR ALTER TABLE common.data_anomalies (
    event_id                INT,
    is_correct_timestamp    BOOLEAN,
    is_correct_process_name BOOLEAN,
    is_late_arrival         BOOLEAN DEFAULT FALSE,   -- ← nouveau champ
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    graph_run_group_id      STRING
);

CREATE OR REPLACE TABLE common.data_to_process (
    event_id        NUMBER,
    event_timestamp TIMESTAMP,
    process_name    STRING,
    process_id      NUMBER,
    message         STRING
);

CREATE OR ALTER TABLE common.logging (
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    graph_run_group_id STRING,
    table_name      STRING,
    n_rows          NUMBER,
    error_message   STRING DEFAULT NULL
);


CREATE OR ALTER TABLE common.transformation_pipeline_status (
    graph_run_group_id STRING,
    started_at         TIMESTAMP,
    finished_at        TIMESTAMP,
    status             STRING
);

-- 1,2) reation des tables staging:

CREATE OR ALTER TABLE staging.hih_listener_manager (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER TABLE staging.hih_hi_broadcast_util (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER TABLE staging.step_stand_step_counter (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER TABLE staging.step_sp_utils (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER TABLE staging.step_lsc (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER  TABLE staging.hih_hi_health_data_insert_store (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER TABLE staging.hih_data_stat_manager (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER  TABLE staging.hih_hi_sync_util (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER  TABLE staging.step_stand_report_receiver (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);

CREATE OR ALTER TABLE staging.step_screen_util (
    event_timestamp TIMESTAMP,
    log_trigger STRING,
    process_id NUMBER,
    message STRING
);
