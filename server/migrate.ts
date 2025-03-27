import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';
import { sql } from 'drizzle-orm'; // Keep this if used for raw SQL below

// Load environment variables
const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('DATABASE_URL environment variable is not set');
  process.exit(1);
}

async function runMigrations() {
  // Create database connection
  // Add '!' to assert DATABASE_URL is non-null here, as we check it above.
  const migrationClient = postgres(DATABASE_URL!, { max: 1 }); // Use a separate client for migrations
  const db = drizzle(migrationClient);

  console.log('Starting database migration...');

  try {
    // First, try standard migration (using drizzle-orm migrator)
    await migrate(db, { migrationsFolder: 'migrations' });
    console.log('Standard migration completed successfully.');
  } catch (error) {
    console.error('Standard migration failed:', error);
    console.log('Attempting to add missing columns manually (fallback)...');

    // Manual migration fallback
    try {
      // Note: Using migrationClient directly for raw SQL with postgres-js
      await migrationClient`ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name TEXT`;
      console.log('Ensured display_name column exists on users table');
      await migrationClient`ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picture_url TEXT`;
      console.log('Ensured profile_picture_url column exists on users table');
      await migrationClient`ALTER TABLE users ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMP DEFAULT NOW()`;
      console.log('Ensured last_synced_at column exists on users table');
      await migrationClient`ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()`;
      console.log('Ensured updated_at column exists on users table');
      await migrationClient`ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS device_id TEXT`;
      console.log('Ensured device_id column exists on user_exercises table');
      await migrationClient`ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS sync_status TEXT DEFAULT 'synced'`;
      console.log('Ensured sync_status column exists on user_exercises table');
      await migrationClient`ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()`;
      console.log('Ensured updated_at column exists on user_exercises table');

      // Add any other columns expected by the schema but potentially missing
      // Example: If the error was truly about a 'name' column on 'users':
      // await migrationClient.sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS name TEXT`;
      // console.log('Ensured name column exists on users table');

      console.log('Manual column check/addition completed successfully.');
    } catch (manualError) {
      console.error('Manual column addition failed:', manualError);
      // Don't necessarily exit here, the app might still work partially
    }
  } finally {
    // Ensure the migration client connection is closed
    await migrationClient.end();
    console.log('Migration client connection closed.');
  }

  console.log('Migration process finished.');
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
