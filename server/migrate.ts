import { drizzle } from 'drizzle-orm/neon-serverless';
import { migrate } from 'drizzle-orm/neon-serverless/migrator';
import { neon } from '@neondatabase/serverless';
import { sql } from 'drizzle-orm';

// Load environment variables
const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('DATABASE_URL environment variable is not set');
  process.exit(1);
}

async function runMigrations() {
  // Create database connection
  const sql = neon(DATABASE_URL);
  const db = drizzle(sql);

  console.log('Starting database migration...');

  try {
    // First, try standard migration (using drizzle-orm migrator)
    await migrate(db, { migrationsFolder: 'migrations' });
    console.log('Standard migration completed successfully.');
  } catch (error) {
    console.error('Standard migration failed:', error);
    console.log('Attempting to add missing columns manually...');

    // Manual migration fallback for backward compatibility
    // Add columns that might be missing in existing tables
    try {
      // Add display_name to users if it doesn't exist
      await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name TEXT`;
      console.log('Added display_name column to users table');

      // Add profile_picture_url to users if it doesn't exist
      await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picture_url TEXT`;
      console.log('Added profile_picture_url column to users table');
      
      // Add last_synced_at to users if it doesn't exist
      await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMP DEFAULT NOW()`;
      console.log('Added last_synced_at column to users table');
      
      // Add updated_at to users if it doesn't exist
      await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()`;
      console.log('Added updated_at column to users table');

      // Add device_id to user_exercises if it doesn't exist
      await sql`ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS device_id TEXT`;
      console.log('Added device_id column to user_exercises table');
      
      // Add sync_status to user_exercises if it doesn't exist
      await sql`ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS sync_status TEXT DEFAULT 'synced'`;
      console.log('Added sync_status column to user_exercises table');
      
      // Add updated_at to user_exercises if it doesn't exist
      await sql`ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()`;
      console.log('Added updated_at column to user_exercises table');

      console.log('Manual migration completed successfully.');
    } catch (manualError) {
      console.error('Manual migration failed:', manualError);
      process.exit(1);
    }
  }

  console.log('Migration process completed.');
}

// Run the migration
runMigrations()
  .then(() => {
    console.log('Database is ready!');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
  });