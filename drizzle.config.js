require('dotenv').config();

/** @type {import('drizzle-kit').Config} */
module.exports = {
  schema: './shared/schema.ts',
  out: './db/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    connectionString: process.env.DATABASE_URL
  }
}; 