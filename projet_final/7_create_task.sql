

USE ROLE app_role;

CREATE OR REPLACE STREAM common.raw_events_stream
    ON TABLE raw.raw_events
    APPEND_ONLY = TRUE;


CREATE OR ALTER TASK common.identify_new_data_task
  WAREHOUSE = COMPUTE_WH
  WHEN SYSTEM$STREAM_HAS_DATA('HEALT_APP_PROJET.COMMON.RAW_EVENTS_STREAM')  -- task qui s'active quand les donnees arrivent
AS
  CALL common.identify_new_data();

CREATE OR ALTER TASK common.data_quality_task
WAREHOUSE = COMPUTE_WH
AFTER common.identify_new_data_task
-- SCHEDULE = '1 HOURS'
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.data_quality(:graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.arrivees_tardives
    WAREHOUSE = COMPUTE_WH
    AFTER common.data_quality_task
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.arrivees_tardives(:graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.hih_listener_manager
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('hih_listener_manager', 'HiH_ListenerManager', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.hih_hibroadcastutil
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('hih_hi_broadcast_util', 'HiH_HiBroadcastUtil', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.step_standstepcounter
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('step_stand_step_counter', 'Step_StandStepCounter', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.step_sputils
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('step_sp_utils', 'Step_SPUtils', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.step_lsc
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('step_lsc', 'Step_LSC', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.hih_hihealthdatainsertstore
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('hih_hi_health_data_insert_store', 'HiH_HiHealthDataInsertStore', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.hih_datastatmanager
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('hih_data_stat_manager', 'HiH_DataStatManager', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.hih_hisyncutil
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('hih_hi_sync_util', 'HiH_HiSyncUtil', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.step_standreportreceiver
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('step_stand_report_receiver', 'Step_StandReportReceiver', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.step_screenutil
WAREHOUSE = COMPUTE_WH
AFTER common.arrivees_tardives
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
BEGIN
    CALL common.enrich_data('step_screen_util', 'Step_ScreenUtil', :graph_run_group_id);
END;
$$;

CREATE OR ALTER TASK common.finalize_transformation
    WAREHOUSE = COMPUTE_WH
    FINALIZE  = 'common.identify_new_data_task'
AS
EXECUTE IMMEDIATE
$$
DECLARE
    graph_run_group_id STRING    := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_RUN_GROUP_ID');
    started_at         TIMESTAMP := SYSTEM$TASK_RUNTIME_INFO('CURRENT_TASK_GRAPH_ORIGINAL_SCHEDULED_TIMESTAMP');
BEGIN
    CALL common.finalize_transformation(:graph_run_group_id, :started_at);
END;
$$;





-- Activation de toutes les tâches enfants

ALTER TASK common.data_quality_task RESUME;
ALTER TASK common.arrivees_tardives RESUME;
ALTER TASK common.hih_listener_manager RESUME;
ALTER TASK common.hih_hibroadcastutil RESUME;
ALTER TASK common.step_standstepcounter RESUME;
ALTER TASK common.step_sputils RESUME;
ALTER TASK common.step_lsc RESUME;
ALTER TASK common.hih_hihealthdatainsertstore RESUME;
ALTER TASK common.hih_datastatmanager RESUME;
ALTER TASK common.hih_hisyncutil RESUME;
ALTER TASK common.step_standreportreceiver RESUME;
ALTER TASK common.step_screenutil RESUME;
ALTER TASK common.finalize_transformation RESUME;

ALTER TASK common.identify_new_data_task RESUME;
-- ALTER TASK common.identify_new_data_task SUSPEND;

-- SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('HEALT_APP_PROJET.COMMON.IDENTIFY_NEW_DATA_TASK');