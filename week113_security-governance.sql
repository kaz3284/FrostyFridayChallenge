-- ============================================================
-- 0: Initialize
-- ============================================================
USER ROLE SYSADMIN;
CREATE DATABASE WEEK113_DB;


-- ============================================================
-- Scenario 1: Data Analyst Team - SSO User Setup
-- ============================================================

-- Use USERADMIN role for user/role management
USE ROLE USERADMIN;

-- Create a custom role for the Data Analyst team
CREATE ROLE IF NOT EXISTS DATA_ANALYST_ROLE
  COMMENT = 'Role for Data Analyst team';

-- Create 5 SSO users (no password = SSO-only authentication)
CREATE USER IF NOT EXISTS ANALYST_USER_01
  LOGIN_NAME    = 'analyst01@example.com'
  DISPLAY_NAME  = 'Analyst User 01'
  EMAIL         = 'analyst01@example.com'
  DEFAULT_ROLE  = 'DATA_ANALYST_ROLE'
  DEFAULT_WAREHOUSE = 'ANALYST_WH'
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Data Analyst team member - SSO only';

CREATE USER IF NOT EXISTS ANALYST_USER_02
  LOGIN_NAME    = 'analyst02@example.com'
  DISPLAY_NAME  = 'Analyst User 02'
  EMAIL         = 'analyst02@example.com'
  DEFAULT_ROLE  = 'DATA_ANALYST_ROLE'
  DEFAULT_WAREHOUSE = 'ANALYST_WH'
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Data Analyst team member - SSO only';

CREATE USER IF NOT EXISTS ANALYST_USER_03
  LOGIN_NAME    = 'analyst03@example.com'
  DISPLAY_NAME  = 'Analyst User 03'
  EMAIL         = 'analyst03@example.com'
  DEFAULT_ROLE  = 'DATA_ANALYST_ROLE'
  DEFAULT_WAREHOUSE = 'ANALYST_WH'
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Data Analyst team member - SSO only';

CREATE USER IF NOT EXISTS ANALYST_USER_04
  LOGIN_NAME    = 'analyst04@example.com'
  DISPLAY_NAME  = 'Analyst User 04'
  EMAIL         = 'analyst04@example.com'
  DEFAULT_ROLE  = 'DATA_ANALYST_ROLE'
  DEFAULT_WAREHOUSE = 'ANALYST_WH'
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Data Analyst team member - SSO only';

CREATE USER IF NOT EXISTS ANALYST_USER_05
  LOGIN_NAME    = 'analyst05@example.com'
  DISPLAY_NAME  = 'Analyst User 05'
  EMAIL         = 'analyst05@example.com'
  DEFAULT_ROLE  = 'DATA_ANALYST_ROLE'
  DEFAULT_WAREHOUSE = 'ANALYST_WH'
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Data Analyst team member - SSO only';

// 確認：ユーザー一覧
show users;

// ユーザー一覧：パスワード・RSA公開鍵・MFAの有無を確認
// ※ワンライナーで必要な情報を表示できるパイプ「->>」を使ったクエリ
SHOW USERS
->> SELECT
    "login_name"           AS LOGIN_NAME,
    "type"                 AS USER_TYPE,
    "has_password"         AS HAS_PASSWORD,
    "has_rsa_public_key"   AS HAS_RSA_PUBLIC_KEY,
    "has_mfa"              AS HAS_MFA,
FROM $1
ORDER BY "name";


-- ※ユーザーを作ったらrole付与は忘れないように
-- Assign DATA_ANALYST_ROLE to each user
GRANT ROLE DATA_ANALYST_ROLE TO USER ANALYST_USER_01;
GRANT ROLE DATA_ANALYST_ROLE TO USER ANALYST_USER_02;
GRANT ROLE DATA_ANALYST_ROLE TO USER ANALYST_USER_03;
GRANT ROLE DATA_ANALYST_ROLE TO USER ANALYST_USER_04;
GRANT ROLE DATA_ANALYST_ROLE TO USER ANALYST_USER_05;

-- ※roleにヒエラルキーを作るのも忘れずに
-- Integrate the role into the role hierarchy
USE ROLE SECURITYADMIN;
GRANT ROLE DATA_ANALYST_ROLE TO ROLE SYSADMIN;

-- warehouse
CREATE WAREHOUSE ANALYST_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 10 --※なるだけ短く設定した方がコストを抑えられる
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE --※必ず入れる：create時に起動してしまうのはもったいないので
  ;

GRANT USAGE ON WAREHOUSE ANALYST_WH TO ROLE DATA_ANALYST_ROLE;

-- Grant read/write access to target databases
GRANT USAGE ON DATABASE WEEK113_DB TO ROLE DATA_ANALYST_ROLE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE WEEK113_DB TO ROLE DATA_ANALYST_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN DATABASE WEEK113_DB TO ROLE DATA_ANALYST_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN DATABASE WEEK113_DB TO ROLE DATA_ANALYST_ROLE;
GRANT SELECT ON ALL VIEWS IN DATABASE WEEK113_DB TO ROLE DATA_ANALYST_ROLE;
GRANT SELECT ON FUTURE VIEWS IN DATABASE WEEK113_DB TO ROLE DATA_ANALYST_ROLE;



-----
-- ※認証（SSO）設定について。
-----
-- 自分はOkta, GoogleWorkspaceともにSAML2で設定。※セキュリティチームと共同作業で実施する：
-- https://docs.snowflake.com/ja/sql-reference/sql/create-security-integration-saml2
-- その他にも、AWS IAM、外部API認証、外部OAuth、Snowflake OAuthなどが用意されている。
-- 
-- ※さらに、SCIM連携を使うとIdP -> Snowflakeへユーザー連携ができるようになる：
-- https://docs.snowflake.com/ja/sql-reference/sql/create-security-integration-scim
-- IdPで管理されるユーザーがSnowflakeへ連携されて、ユーザー作成、roleの紐付け、無効化が連携されるようになる。



-- ============================================================
-- Scenario 2: ETL Process Automation - Key-Pair Auth Service Account
-- ============================================================

-- Use USERADMIN role for user/role management
USE ROLE USERADMIN;

-- Create a custom role for the ETL service account
CREATE ROLE IF NOT EXISTS ETL_SERVICE_ROLE
  COMMENT = 'Role for automated ETL pipeline service account';

-- Create the service account (key-pair auth only, no password, no MFA)
CREATE USER IF NOT EXISTS SVC_ETL_PIPELINE
  LOGIN_NAME        = 'SVC_ETL_PIPELINE'
  DISPLAY_NAME      = 'ETL Pipeline Service Account'
  TYPE              = SERVICE
  DEFAULT_ROLE      = 'ETL_SERVICE_ROLE'
  DEFAULT_WAREHOUSE = 'ETL_WH'
  RSA_PUBLIC_KEY    = '<PUBLIC_KEY>'
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Service account for daily ETL pipeline - key-pair auth only';


-- Assign ETL_SERVICE_ROLE to the service account
GRANT ROLE ETL_SERVICE_ROLE TO USER SVC_ETL_PIPELINE;

-- Integrate the role into the role hierarchy
USE ROLE SECURITYADMIN;
GRANT ROLE ETL_SERVICE_ROLE TO ROLE SYSADMIN;

-- Create and grant a dedicated warehouse for ETL
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS ETL_WH
  WAREHOUSE_SIZE    = 'MEDIUM'
  AUTO_SUSPEND      = 10
  AUTO_RESUME       = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Dedicated warehouse for ETL pipeline';

USE ROLE SECURITYADMIN;
GRANT USAGE, OPERATE ON WAREHOUSE ETL_WH TO ROLE ETL_SERVICE_ROLE;

-- Grant permissions on source databases (read)
GRANT USAGE ON DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;
GRANT SELECT ON ALL TABLES IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;
GRANT SELECT ON FUTURE TABLES IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;

-- Grant permissions on target database (read/write)
GRANT USAGE ON DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;
GRANT CREATE TABLE ON ALL SCHEMAS IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON FUTURE TABLES IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;

-- Grant stage access for data loading (if applicable)
GRANT USAGE ON ALL STAGES IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;
GRANT READ, WRITE ON ALL STAGES IN DATABASE WEEK113_DB TO ROLE ETL_SERVICE_ROLE;

-- (Optional) Set up key rotation - assign a second public key
-- ALTER USER SVC_ETL_PIPELINE SET RSA_PUBLIC_KEY_2 = 'MIIBIjANBgkqh...<SECOND_RSA_PUBLIC_KEY>...';
-- After rotating to the new key:
-- ALTER USER SVC_ETL_PIPELINE UNSET RSA_PUBLIC_KEY;
-- ALTER USER SVC_ETL_PIPELINE SET RSA_PUBLIC_KEY = '<NEW_KEY>';


-- ============================================================
-- Scenario 3: Legacy System Integration - Password-Based Auth
-- ============================================================
-- WARNING: TYPE = LEGACY_SERVICE is being deprecated by Snowflake.
--   Phase 2 (May-Jul 2026): No new LEGACY_SERVICE users can be created.
--   Phase 3 (Aug-Oct 2026): All LEGACY_SERVICE users are migrated to SERVICE
--                           and password auth is blocked.
--   Plan migration to key-pair auth or OAuth before the deadline.
-- ============================================================

-- Use USERADMIN role for user/role management
USE ROLE USERADMIN;

-- Create a custom role for the legacy reporting tool
CREATE ROLE IF NOT EXISTS LEGACY_REPORT_ROLE
  COMMENT = 'Role for legacy reporting tool - temporary until key-pair migration';

-- Create the legacy service account (password auth)
CREATE USER IF NOT EXISTS SVC_LEGACY_REPORT
  LOGIN_NAME        = 'SVC_LEGACY_REPORT'
  DISPLAY_NAME      = 'Legacy Reporting Tool Service Account'
  PASSWORD          = '<STRONG_PASSWORD_HERE>'
  TYPE              = LEGACY_SERVICE
  DEFAULT_ROLE      = 'LEGACY_REPORT_ROLE'
  DEFAULT_WAREHOUSE = 'REPORT_WH'
  MUST_CHANGE_PASSWORD = FALSE
  DAYS_TO_EXPIRY    = 3
  COMMENT = 'Legacy reporting tool - password auth (migrate to key-pair by 2026-08)';

-- ※2026年8月〜10月：既存の LEGACY_SERVICE ユーザーが自動的に SERVICE に移行され、パスワード認証がブロックされる

-- ※パスワード認証の場合はネットワークアクセス制限も必ずセットで！！！
CREATE NETWORK POLICY IF NOT EXISTS legacy_report_network_policy
  ALLOWED_IP_LIST = ('<REPORTING_SERVER_IP>/32')
  COMMENT = 'Restrict legacy reporting tool to known server IP';

ALTER USER SVC_LEGACY_REPORT SET NETWORK_POLICY = 'legacy_report_network_policy';

-- ※AUTHENTICATION_METHODS = ('PASSWORD') を明示的に設定することで、
-- このアカウントが意図的にパスワード認証を使用していることを文書化する
-- 監査時に「なぜこのアカウントはパスワード認証なのか」を明確に説明できるようにする
USE ROLE ACCOUNTADMIN;
CREATE AUTHENTICATION POLICY IF NOT EXISTS legacy_report_auth_policy
  AUTHENTICATION_METHODS = ('PASSWORD')
  COMMENT = 'Auth policy for legacy reporting tool - password only until migration';

ALTER USER SVC_LEGACY_REPORT SET AUTHENTICATION POLICY = legacy_report_auth_policy;

-- Migration preparation - pre-assign RSA key when ready
-- When the legacy tool is upgraded, run:
-- ALTER USER SVC_LEGACY_REPORT SET RSA_PUBLIC_KEY = '<PUBLIC_KEY>';
-- ALTER USER SVC_LEGACY_REPORT SET TYPE = SERVICE;
-- ALTER USER SVC_LEGACY_REPORT UNSET PASSWORD;

-- Assign LEGACY_REPORT_ROLE to the service account
GRANT ROLE LEGACY_REPORT_ROLE TO USER SVC_LEGACY_REPORT;

-- Integrate the role into the role hierarchy
USE ROLE SECURITYADMIN;
GRANT ROLE LEGACY_REPORT_ROLE TO ROLE SYSADMIN;

-- Create and grant a dedicated warehouse for reporting
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS REPORT_WH
  WAREHOUSE_SIZE    = 'SMALL'
  AUTO_SUSPEND      = 5
  AUTO_RESUME       = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Dedicated warehouse for legacy reporting tool';

USE ROLE SECURITYADMIN;
GRANT USAGE ON WAREHOUSE REPORT_WH TO ROLE LEGACY_REPORT_ROLE;

-- Step 7: Grant read-only access to reporting databases
GRANT USAGE ON DATABASE WEEK113_DB TO ROLE LEGACY_REPORT_ROLE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE WEEK113_DB TO ROLE LEGACY_REPORT_ROLE;
GRANT SELECT ON ALL TABLES IN DATABASE WEEK113_DB TO ROLE LEGACY_REPORT_ROLE;
GRANT SELECT ON FUTURE TABLES IN DATABASE WEEK113_DB TO ROLE LEGACY_REPORT_ROLE;
GRANT SELECT ON ALL VIEWS IN DATABASE WEEK113_DB TO ROLE LEGACY_REPORT_ROLE;
GRANT SELECT ON FUTURE VIEWS IN DATABASE WEEK113_DB TO ROLE LEGACY_REPORT_ROLE;




-- ============================================================
-- Scenario 4: Monitoring & Query History Analysis
-- ============================================================

-- Use USERADMIN role for user/role management
USE ROLE USERADMIN;


-- Create the monitoring service account (key-pair auth only)
CREATE USER IF NOT EXISTS SVC_QUERY_MONITOR
  LOGIN_NAME        = 'SVC_QUERY_MONITOR'
  DISPLAY_NAME      = 'Query History Monitoring Service'
  TYPE              = SERVICE
  DEFAULT_ROLE      = 'MONITORING_SERVICE_ROLE'
  DEFAULT_WAREHOUSE = 'MONITORING_WH'
  RSA_PUBLIC_KEY    = '<PUBLIC_KEY>'
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Service account for periodic query history analysis - key-pair auth only';

-- create role
CREATE ROLE IF NOT EXISTS MONITORING_SERVICE_ROLE
  COMMENT = 'Role for automated query history monitoring and performance analysis';

---
-- ※ACCOUNT_USAGE ビューへのアクセスには、IMPORTED PRIVILEGES ではなく、用途に応じた SNOWFLAKE データベースロール を個別に付与する。
-- すべてのデータベースロールを付与する必要はなく、監視の目的に応じて選択する
-- IMPORTED PRIVILEGES は全ビューへのアクセスを付与するため、監視専用アカウントには過剰
--- 
-- Assign MONITORING_SERVICE_ROLE to the service account
GRANT ROLE MONITORING_SERVICE_ROLE TO USER SVC_QUERY_MONITOR;

-- Integrate the role into the role hierarchy
USE ROLE SECURITYADMIN;
GRANT ROLE MONITORING_SERVICE_ROLE TO ROLE SYSADMIN;

-- Grant access to SNOWFLAKE database via database roles
-- QUERY_HISTORY requires GOVERNANCE_VIEWER
-- WAREHOUSE_METERING_HISTORY, TASK_HISTORY, etc. require USAGE_VIEWER
-- LOGIN_HISTORY requires SECURITY_VIEWER
USE ROLE ACCOUNTADMIN;
GRANT DATABASE ROLE SNOWFLAKE.GOVERNANCE_VIEWER TO ROLE MONITORING_SERVICE_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.USAGE_VIEWER      TO ROLE MONITORING_SERVICE_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.OBJECT_VIEWER      TO ROLE MONITORING_SERVICE_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.SECURITY_VIEWER    TO ROLE MONITORING_SERVICE_ROLE;

---
-- ※ACCOUNT_USAGE vs INFORMATION_SCHEMA の使い分け
-- ACCOUNT_USAGE	           INFORMATION_SCHEMA
-- データ遅延	45分〜3時間           なし（リアルタイム）
-- 保持期間	365日                7日〜6ヶ月
-- 削除済みオブジェクト	含む	     含まない
---


-- Create a dedicated monitoring warehouse (small, auto-suspend aggressively)
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS MONITORING_WH
  WAREHOUSE_SIZE    = 'XSMALL'
  AUTO_SUSPEND      = 10
  AUTO_RESUME       = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Dedicated warehouse for monitoring and query history analysis';

USE ROLE SECURITYADMIN;
GRANT USAGE ON WAREHOUSE MONITORING_WH TO ROLE MONITORING_SERVICE_ROLE;

-- (Optional) Grant MONITOR on all warehouses for real-time query monitoring
-- This allows querying INFORMATION_SCHEMA.QUERY_HISTORY (no latency, 7-day retention)
USE ROLE SECURITYADMIN;
GRANT MONITOR ON ALL WAREHOUSES IN ACCOUNT TO ROLE MONITORING_SERVICE_ROLE;

-- (Optional) Grant access to a results database for storing analysis output
-- If the monitoring service writes summary tables or alerting data
GRANT USAGE ON DATABASE WEEK113_DB TO ROLE MONITORING_SERVICE_ROLE;
GRANT USAGE ON SCHEMA WEEK113_DB.MONITORING TO ROLE MONITORING_SERVICE_ROLE;
GRANT CREATE TABLE ON SCHEMA WEEK113_DB.MONITORING TO ROLE MONITORING_SERVICE_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA WEEK113_DB.MONITORING TO ROLE MONITORING_SERVICE_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA WEEK113_DB.MONITORING TO ROLE MONITORING_SERVICE_ROLE;

-- Apply Network Policy
CREATE NETWORK POLICY IF NOT EXISTS monitoring_network_policy
  ALLOWED_IP_LIST = ('<MONITORING_SERVER_IP>/32')
  COMMENT = 'Restrict monitoring service to known server IP';

ALTER USER SVC_QUERY_MONITOR SET NETWORK_POLICY = 'monitoring_network_policy';

-- (Optional) Schedule as Snowflake Task for autonomous execution
-- Example: Daily query performance summary
-- USE ROLE SYSADMIN;
-- CREATE OR REPLACE TASK monitoring_daily_summary
--   WAREHOUSE = 'MONITORING_WH'
--   SCHEDULE  = 'USING CRON 0 6 * * * Asia/Tokyo'
--   COMMENT   = 'Daily query performance analysis at 6:00 AM JST'
-- AS
--   INSERT INTO <MONITORING_DATABASE>.<MONITORING_SCHEMA>.DAILY_QUERY_SUMMARY
--   SELECT
--     CURRENT_DATE()                           AS REPORT_DATE,
--     WAREHOUSE_NAME,
--     COUNT(*)                                 AS TOTAL_QUERIES,
--     AVG(EXECUTION_TIME) / 1000               AS AVG_EXECUTION_SEC,
--     MAX(EXECUTION_TIME) / 1000               AS MAX_EXECUTION_SEC,
--     SUM(BYTES_SPILLED_TO_LOCAL_STORAGE)       AS TOTAL_BYTES_SPILLED_LOCAL,
--     SUM(BYTES_SPILLED_TO_REMOTE_STORAGE)      AS TOTAL_BYTES_SPILLED_REMOTE,
--     COUNT_IF(EXECUTION_STATUS = 'FAIL')       AS FAILED_QUERIES
--   FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
--   WHERE START_TIME >= DATEADD(DAY, -1, CURRENT_TIMESTAMP())
--   GROUP BY WAREHOUSE_NAME;
--
-- ALTER TASK monitoring_daily_summary RESUME;

