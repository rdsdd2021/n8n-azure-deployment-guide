// Clear remaining n8n tables from Supabase
const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres:B@ssDr0p@db.slicsqdcgwxgfvlmnrqz.supabase.co:5432/postgres',
  ssl: { rejectUnauthorized: false }
});

async function clearRemainingTables() {
  try {
    await client.connect();
    console.log('Connected to Supabase database');

    // Additional tables found
    const remainingTables = [
      'annotation_tag_entity',
      'data_store',
      'data_store_column',
      'event_destinations',
      'execution_annotation_tags',
      'execution_annotations',
      'folder_tag',
      'insights_by_period',
      'insights_metadata',
      'insights_raw',
      'project_relation',
      'role_scope',
      'scope',
      'user',
      'user_api_keys',
      'workflow_history',
      'workflows_tags'
    ];

    console.log(`Dropping ${remainingTables.length} remaining tables...`);

    for (const table of remainingTables) {
      try {
        await client.query(`DROP TABLE IF EXISTS ${table} CASCADE`);
        console.log(`✓ Dropped table: ${table}`);
      } catch (error) {
        console.log(`✗ Could not drop ${table}: ${error.message}`);
      }
    }

    console.log('All n8n tables cleared!');

    // Final check
    const result = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name NOT IN ('spatial_ref_sys', 'geography_columns', 'geometry_columns', 'raster_columns', 'raster_overviews', 'migrations')
      ORDER BY table_name
    `);

    console.log(`Final remaining tables: ${result.rows.length}`);
    result.rows.forEach(row => console.log(`  - ${row.table_name}`));

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

clearRemainingTables();