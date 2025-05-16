const { Client } = require('pg');

const connectionString = 'postgresql://ptadmin:NewStrongPassword123!@ptchampion-db.postgres.database.azure.com:5432/ptchampion?sslmode=require';

const client = new Client({
  connectionString,
});

async function checkDatabase() {
  try {
    await client.connect();
    console.log('Connected to database');
    
    // Check all tables in the database
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema='public'
      ORDER BY table_name
    `);
    
    console.log('\nAll tables in database:');
    tablesResult.rows.forEach(row => {
      console.log(`- ${row.table_name}`);
    });
    
    // Check if user_social_accounts table exists
    const socialTableResult = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_social_accounts'
      );
    `);
    
    const hasSocialTable = socialTableResult.rows[0].exists;
    console.log(`\nuser_social_accounts table exists: ${hasSocialTable}`);
    
    // Check for any tables that might handle social identities
    const socialTablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema='public' 
      AND (
        table_name LIKE '%social%' 
        OR table_name LIKE '%identity%' 
        OR table_name LIKE '%auth%' 
        OR table_name LIKE '%provider%'
        OR table_name LIKE '%oauth%'
        OR table_name LIKE '%credential%'
      )
      ORDER BY table_name
    `);
    
    console.log('\nPotential social identity tables:');
    if (socialTablesResult.rows.length > 0) {
      socialTablesResult.rows.forEach(row => {
        console.log(`- ${row.table_name}`);
      });
    } else {
      console.log('None found');
    }
    
    // Check users table columns to see if it has provider fields
    const usersColumnsResult = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'users'
      ORDER BY column_name
    `);
    
    console.log('\nUsers table columns:');
    usersColumnsResult.rows.forEach(row => {
      console.log(`- ${row.column_name} (${row.data_type})`);
    });
    
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.end();
    console.log('\nConnection closed');
  }
}

checkDatabase(); 