
USE ROLE dev_ops_role;
USE WAREHOUSE MY_WH;

CREATE OR REPLACE FUNCTION common.check_correct_timestamp(event_timestamp TIMESTAMP)
RETURNS BOOLEAN
LANGUAGE SQL
AS
$$
    event_timestamp > '2016-01-01 00:00:00'::TIMESTAMP AND event_timestamp <=CURRENT_TIMESTAMP()
$$;

CREATE OR REPLACE FUNCTION common.check_correct_process_name(process_name STRING)
RETURNS BOOLEAN
LANGUAGE SQL
AS
$$
    process_name IN ('Step_StandReportReceiver','HiH_HiBroadcastUtil','Step_HGNH','Step_SPUtils','Step_StandStepDataManager','Step_ExtSDM','HiH_HiHealthDataInsertStore','HiH_HiSyncUtil','Step_DataCache','Step_StandStepCounter','Step_ScreenUtil','HiH_DataStatManager','HiH_HiAppUtil','HiH_HiHealthBinder','HiH_ListenerManager','HiH_HiSyncControl','Step_LSC','Step_FlushableStepDataCache','Step_NotificationUtil')
$$;

CREATE OR REPLACE FUNCTION common.extract_log_trigger(message STRING)
  RETURNS STRING
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.12'
  HANDLER = 'extract_log_trigger'
AS $$
def extract_log_trigger(message: str):
       return message.strip().split(" ")[0].split(":")[0].split("=")[0].strip()
$$;


CREATE OR REPLACE FUNCTION common.extract_log_message(message STRING)
  RETURNS STRING
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.12'
  HANDLER = 'extract_log_trigger'
AS $$
def extract_log_trigger(message: str):
       msg_trigger = message.strip().split(" ")[0].split(":")[0].split("=")[0].strip()
       return message.replace(msg_trigger, "").strip()
$$;

CREATE OR REPLACE FUNCTION common.check_late_arrival(event_timestamp TIMESTAMP)
RETURNS BOOLEAN
LANGUAGE SQL
AS
$$
    -- DATEDIFF('day', event_timestamp, CURRENT_TIMESTAMP()) > 5
     event_timestamp < '2017-12-24'::TIMESTAMP
$$;

