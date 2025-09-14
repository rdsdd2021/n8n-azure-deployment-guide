// Clear n8n Database Tables from Supabase
const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres:B@ssDr0p@db.slicsqdcgwxgfvlmnrqz.supabase.co:5432/postgres',
  ssl: { rejectUnauthorized: false }
});

async function clearDatabase() {
  try {
    await client.connect();
    console.log('Connected to Supabase database');

    // Disable foreign key checks
    await client.query('SET session_replication_role = replica');

    // List of tables to drop
    const tables = [
      'test_case_execution',
      'test_run',
      'test_metric',
      'test_definition',
      'processed_data',
      'annotation_tag_mapping',
      'tag_entity',
      'annotation',
      'execution_annotation',
      'execution_metadata',
      'execution_data',
      'execution_entity',
      'workflow_statistics',
      'workflow_entity',
      'webhook_entity',
      'variables',
      'user_project',
      'shared_workflow',
      'shared_credentials',
      'settings',
      'project',
      'invalid_auth_token',
      'installed_packages',
      'installed_nodes',
      'credentials_entity',
      'auth_user',
      'auth_identity',
      'auth_provider_sync_history',
      'api_key',
      'workflow_shared',
      'credentials_shared',
      'user_entity',
      'role',
      'folder',
      'insights_relation',
      'insights_entity',
      'data_tables'
    ];

    console.log(`Dropping ${tables.length} tables...`);

    for (const table of tables) {
      try {
        await client.query(`DROP TABLE IF EXISTS ${table} CASCADE`);
        console.log(`✓ Dropped table: ${table}`);
      } catch (error) {
        console.log(`✗ Could not drop ${table}: ${error.message}`);
      }
    }

    // Re-enable foreign key checks
    await client.query('SET session_replication_role = DEFAULT');

    console.log('Database cleared successfully!');

    // Check remaining tables
    const result = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name NOT IN ('spatial_ref_sys', 'geography_columns', 'geometry_columns', 'raster_columns', 'raster_overviews')
      ORDER BY table_name
    `);

    console.log(`Remaining tables: ${result.rows.length}`);
    result.rows.forEach(row => console.log(`  - ${row.table_name}`));

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

clearDatabase();