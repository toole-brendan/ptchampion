const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = 'postgresql://ptadmin:NewStrongPassword123!@ptchampion-db.postgres.database.azure.com:5432/ptchampion?sslmode=require';

// Path to migration files
const upMigrationPath = path.join(__dirname, '..', 'sql', 'migrations', '202505161200_add_social_accounts_table.up.sql');
const downMigrationPath = path.join(__dirname, '..', 'sql', 'migrations', '202505161200_add_social_accounts_table.down.sql');

// Function to read migration file
function readMigrationFile(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch (err) {
    console.error(`Error reading migration file ${filePath}:`, err);
    return null;
  }
}

async function executeMigration() {
  const client = new Client({
    connectionString,
  });

  try {
    // Connect to the database
    await client.connect();
    console.log('Connected to database');
    
    // Check if the table already exists
    const tableExistsQuery = `
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_social_accounts'
      );
    `;
    
    const tableExistsResult = await client.query(tableExistsQuery);
    const tableExists = tableExistsResult.rows[0].exists;
    
    if (tableExists) {
      console.log('user_social_accounts table already exists. Skipping migration.');
      return;
    }
    
    // Read the up migration SQL
    const upMigrationSQL = readMigrationFile(upMigrationPath);
    if (!upMigrationSQL) {
      throw new Error('Could not read up migration file');
    }
    
    console.log('Executing migration...');
    console.log('Migration SQL:\n', upMigrationSQL);
    
    // Execute the migration within a transaction
    await client.query('BEGIN');
    
    try {
      // Execute the migration
      await client.query(upMigrationSQL);
      
      // Add to schema_migrations if that table exists
      const schemaExists = await client.query(`
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = 'schema_migrations'
        );
      `);
      
      if (schemaExists.rows[0].exists) {
        await client.query(`
          INSERT INTO schema_migrations (version, dirty) 
          VALUES ('202505161200', FALSE)
          ON CONFLICT (version) DO NOTHING;
        `);
        console.log('Added migration to schema_migrations table');
      }
      
      await client.query('COMMIT');
      console.log('Migration successful!');
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Migration failed:', err);
      throw err;
    }
    
    // Verify the table was created
    const verifyTableQuery = `
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'user_social_accounts'
      ORDER BY ordinal_position;
    `;
    
    const columnsResult = await client.query(verifyTableQuery);
    
    console.log('\nTable structure:');
    columnsResult.rows.forEach(row => {
      console.log(`- ${row.column_name} (${row.data_type})`);
    });
    
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.end();
    console.log('Connection closed');
  }
}

// Execute the migration
executeMigration(); 