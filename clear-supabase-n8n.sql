-- Clear n8n Database Tables from Supabase
-- Run this script to completely reset your n8n instance

-- Disable foreign key checks temporarily
SET session_replication_role = replica;

-- Drop all n8n tables in correct order (to handle foreign key constraints)
DROP TABLE IF EXISTS test_case_execution CASCADE;
DROP TABLE IF EXISTS test_run CASCADE;
DROP TABLE IF EXISTS test_metric CASCADE;
DROP TABLE IF EXISTS test_definition CASCADE;
DROP TABLE IF EXISTS processed_data CASCADE;
DROP TABLE IF EXISTS annotation_tag_mapping CASCADE;
DROP TABLE IF EXISTS tag_entity CASCADE;
DROP TABLE IF EXISTS annotation CASCADE;
DROP TABLE IF EXISTS execution_annotation CASCADE;
DROP TABLE IF EXISTS execution_metadata CASCADE;
DROP TABLE IF EXISTS execution_data CASCADE;
DROP TABLE IF EXISTS execution_entity CASCADE;
DROP TABLE IF EXISTS workflow_statistics CASCADE;
DROP TABLE IF EXISTS workflow_entity CASCADE;
DROP TABLE IF EXISTS webhook_entity CASCADE;
DROP TABLE IF EXISTS variables CASCADE;
DROP TABLE IF EXISTS user_project CASCADE;
DROP TABLE IF EXISTS shared_workflow CASCADE;
DROP TABLE IF EXISTS shared_credentials CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS project CASCADE;
DROP TABLE IF EXISTS invalid_auth_token CASCADE;
DROP TABLE IF EXISTS installed_packages CASCADE;
DROP TABLE IF EXISTS installed_nodes CASCADE;
DROP TABLE IF EXISTS credentials_entity CASCADE;
DROP TABLE IF EXISTS auth_user CASCADE;
DROP TABLE IF EXISTS auth_identity CASCADE;
DROP TABLE IF EXISTS auth_provider_sync_history CASCADE;
DROP TABLE IF EXISTS api_key CASCADE;
DROP TABLE IF EXISTS workflow_shared CASCADE;
DROP TABLE IF EXISTS credentials_shared CASCADE;
DROP TABLE IF EXISTS user_entity CASCADE;
DROP TABLE IF EXISTS role CASCADE;
DROP TABLE IF EXISTS folder CASCADE;
DROP TABLE IF EXISTS insights_relation CASCADE;
DROP TABLE IF EXISTS insights_entity CASCADE;
DROP TABLE IF EXISTS data_tables CASCADE;

-- Drop any remaining sequences that might exist
DROP SEQUENCE IF EXISTS workflow_entity_id_seq CASCADE;
DROP SEQUENCE IF EXISTS user_entity_id_seq CASCADE;
DROP SEQUENCE IF EXISTS execution_entity_id_seq CASCADE;
DROP SEQUENCE IF EXISTS credentials_entity_id_seq CASCADE;

-- Re-enable foreign key checks
SET session_replication_role = DEFAULT;

-- Verify all tables are dropped
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name NOT IN ('spatial_ref_sys', 'geography_columns', 'geometry_columns', 'raster_columns', 'raster_overviews')
ORDER BY table_name;