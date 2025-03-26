#!/usr/bin/env node

// This script migrates plaintext passwords to bcrypt hashed passwords
// Run with: NODE_ENV=production node scripts/migrate-passwords.js

import bcrypt from 'bcrypt';
import pg from 'pg';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config({ path: process.env.NODE_ENV === 'production' ? '.env.production' : '.env' });

const SALT_ROUNDS = 12;

// Function to check if a password is already hashed with bcrypt
function isBcryptHash(str) {
  return /^\$2[ayb]\$[0-9]{2}\$[A-Za-z0-9./]{53}$/.test(str);
}

// Connect to database
async function migratePasswords() {
  console.log('Starting password migration...');
  console.log(`Using database: ${process.env.DATABASE_URL}`);
  
  const client = new pg.Client({
    connectionString: process.env.DATABASE_URL,
  });
  
  try {
    await client.connect();
    console.log('Connected to database');
    
    // Get all users
    const { rows: users } = await client.query('SELECT id, username, password FROM users');
    console.log(`Found ${users.length} users`);
    
    // Process each user
    let migratedCount = 0;
    let alreadyHashedCount = 0;
    
    for (const user of users) {
      // Skip if password is already a bcrypt hash
      if (isBcryptHash(user.password)) {
        console.log(`User ${user.username} (ID: ${user.id}) already has hashed password`);
        alreadyHashedCount++;
        continue;
      }
      
      // Hash the password
      console.log(`Migrating password for user ${user.username} (ID: ${user.id})`);
      const hashedPassword = await bcrypt.hash(user.password, SALT_ROUNDS);
      
      // Update the user record
      await client.query(
        'UPDATE users SET password = $1, updated_at = NOW() WHERE id = $2',
        [hashedPassword, user.id]
      );
      
      migratedCount++;
    }
    
    console.log(`Migration complete. Results:`);
    console.log(`- Total users: ${users.length}`);
    console.log(`- Already hashed: ${alreadyHashedCount}`);
    console.log(`- Migrated: ${migratedCount}`);
    
  } catch (err) {
    console.error('Error during migration:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Run the migration
migratePasswords().catch(console.error);
