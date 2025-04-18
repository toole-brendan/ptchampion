# Database Migrations

This directory contains all database migrations for the PT Champion application. The migrations are managed using [golang-migrate](https://github.com/golang-migrate/migrate).

## Migration File Structure

Each migration consists of two files:
- `####_description.up.sql`: Contains SQL statements to apply the migration
- `####_description.down.sql`: Contains SQL statements to revert the migration

The `####` prefix is a sequential number (starting from `0001`) that determines the order of migrations.

## Creating New Migrations

To create a new migration, follow these steps:

1. Determine the next available migration number by looking at the existing files
2. Create two new files with the proper naming convention:
   ```
   ####_description.up.sql
   ####_description.down.sql
   ```
3. Add the SQL statements to perform the migration in the `.up.sql` file
4. Add the SQL statements to revert the migration in the `.down.sql` file

Example:
```
0008_add_user_preferences.up.sql
0008_add_user_preferences.down.sql
```

## Running Migrations

The migrations are automatically run during deployment and tested in CI, but you can also run them manually using the golang-migrate tool:

### Install golang-migrate

Follow the installation instructions at [golang-migrate GitHub repository](https://github.com/golang-migrate/migrate/tree/master#installation).

### Apply Migrations

To apply all pending migrations:

```bash
migrate -path db/migrations -database "postgres://user:password@localhost:5432/ptchampion?sslmode=disable" up
```

To apply a specific number of migrations:

```bash
migrate -path db/migrations -database "postgres://user:password@localhost:5432/ptchampion?sslmode=disable" up 1
```

### Rollback Migrations

To roll back the most recent migration:

```bash
migrate -path db/migrations -database "postgres://user:password@localhost:5432/ptchampion?sslmode=disable" down 1
```

To roll back all migrations:

```bash
migrate -path db/migrations -database "postgres://user:password@localhost:5432/ptchampion?sslmode=disable" down
```

## Migration Guidelines

1. Always create both `up` and `down` migrations
2. Make migrations idempotent when possible (use `IF NOT EXISTS`, `IF EXISTS`, etc.)
3. Keep migrations small and focused on a single responsibility
4. Add comments to describe the purpose of the migration
5. Test migrations locally before committing them
6. For complex schema changes, consider using multiple smaller migrations

## CI Validation

The GitHub Actions workflow validates all migrations by:

1. Checking that migration files follow the proper naming convention
2. Verifying that every `up` migration has a corresponding `down` migration
3. Testing that migrations can be applied and rolled back successfully

Pull requests that don't pass these validations will be blocked from merging. 