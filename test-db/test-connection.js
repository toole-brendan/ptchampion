const { Client } = require('pg');

const connectionString = 'postgresql://ptadmin:NewStrongPassword123!@ptchampion-db.postgres.database.azure.com:5432/ptchampion?sslmode=require';

const client = new Client({
  connectionString,
});

console.log('Attempting to connect to PostgreSQL database...');

// Create a timeout reference
let timeoutId;

client.connect()
  .then(() => {
    console.log('Connection successful!');
    return client.query('SELECT version()');
  })
  .then(result => {
    console.log('PostgreSQL Version:', result.rows[0].version);
    return client.query('SELECT current_database()');
  })
  .then(result => {
    console.log('Current Database:', result.rows[0].current_database);
    return client.query('SELECT current_user');
  })
  .then(result => {
    console.log('Current User:', result.rows[0].current_user);
    // List some tables (if any)
    return client.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public'");
  })
  .then(result => {
    console.log('Tables in public schema:', result.rows.map(row => row.table_name).join(', ') || 'No tables found');
    return client.end();
  })
  .then(() => {
    console.log('Connection closed successfully');
    // Clear the timeout since we completed successfully
    clearTimeout(timeoutId);
    process.exit(0);
  })
  .catch(err => {
    console.error('Connection error:', err);
    // Try to close the client even if there was an error
    try {
      client.end();
    } catch (closeErr) {
      console.error('Error closing client:', closeErr);
    }
    clearTimeout(timeoutId);
    process.exit(1);
  });

// Set a timeout to prevent hanging indefinitely
timeoutId = setTimeout(() => {
  console.log('Connection attempt timed out after 10 seconds');
  process.exit(1);
}, 10000); 