# Database Schema Management Guide

This document outlines the procedures for managing database schema changes for both development and production environments in the `ptchampion` project.

## Overview

We use `golang-migrate/migrate` (invoked via `make` commands) as the primary tool for managing and applying database migrations. Migrations are defined as pairs of SQL files (`.up.sql` and `.down.sql`) located in the `sql/migrations/` directory.

**Key Principles:**
- Migrations should be idempotent (safe to run multiple times).
- Every `.up.sql` migration should have a corresponding `.down.sql` migration to revert the changes.
- Test migrations thoroughly in a development or staging environment before applying to production.
- All migration files must be committed to version control.

## Migration File Naming Convention

Migration files should follow this pattern:
`VERSION_descriptive_name.up.sql`
`VERSION_descriptive_name.down.sql`

Where:
- `VERSION`: A unique identifier for the migration. This can be:
    - A timestamp (e.g., `YYYYMMDDHHMMSS` like `20250509235822`). This is generally preferred for ensuring chronological order.
    - A sequential number (e.g., `000001`, `000002`). The `make migrate-create` command uses this format.
- `descriptive_name`: A short description of the change (e.g., `add_tokens_invalidated_at_to_users`).

**Example:**
- `sql/migrations/20250509235822_add_tokens_invalidated_at_to_users.up.sql`
- `sql/migrations/20250509235822_add_tokens_invalidated_at_to_users.down.sql`

## Creating New Migrations

1.  **Using the Makefile (Recommended for basic structure):**
    The `Makefile` provides a helper to create the file structure:
    ```bash
    make migrate-create name=your_migration_description
    ```
    For example: `make migrate-create name=add_indexes_to_workouts_table`
    This will create two files in `sql/migrations/` like:
    - `XXXX_your_migration_description.up.sql`
    - `XXXX_your_migration_description.down.sql`
    (`XXXX` will be the next available sequence number).

    *Note:* You might prefer to rename the `XXXX` prefix to a timestamp for better global ordering if you have multiple developers creating migrations.

2.  **Manual Creation:**
    Alternatively, you can create the files manually in the `sql/migrations/` directory, ensuring they follow the naming convention.

3.  **Writing Migration SQL:**
    -   **`.up.sql` file:** Contains the SQL statements to apply the desired schema changes (e.g., `CREATE TABLE`, `ALTER TABLE ADD COLUMN`).
        ```sql
        -- Example: sql/migrations/YYYYMMDDHHMMSS_add_new_feature_flag.up.sql
        ALTER TABLE users ADD COLUMN new_feature_enabled BOOLEAN DEFAULT false;
        ```
    -   **`.down.sql` file:** Contains the SQL statements to revert the changes made by the corresponding `.up.sql` file (e.g., `DROP TABLE`, `ALTER TABLE DROP COLUMN`).
        ```sql
        -- Example: sql/migrations/YYYYMMDDHHMMSS_add_new_feature_flag.down.sql
        ALTER TABLE users DROP COLUMN IF EXISTS new_feature_enabled;
        ```
        It's crucial to implement the down migration correctly. If a change is irreversible or a down migration is not applicable, the file should still exist but can contain a comment indicating this.

## Development Environment

The development database connection details are typically sourced from an environment file (e.g., `.env.dev`).

1.  **Load Environment Variables:**
    Ensure your development environment variables are loaded into your shell. This usually contains `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, and `DB_SSL_MODE`.
    ```bash
    source .env.dev  # Or your specific development environment file
    ```

2.  **Apply Migrations:**
    To apply all pending migrations (i.e., `.up.sql` files that haven't been run yet):
    ```bash
    make migrate-up
    ```
    The `Makefile` uses these environment variables to construct the connection string for the `migrate` tool.

3.  **Rollback Migrations:**
    To roll back the most recently applied migration:
    ```bash
    make migrate-down
    ```
    This will execute the corresponding `.down.sql` file. To roll back multiple migrations, you can run this command multiple times.

4.  **Check Schema (using `psql`):**
    After applying migrations, you can verify the schema changes directly using `psql`:
    ```bash
    # Ensure .env.dev is sourced
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" \\
      -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'your_table_name' ORDER BY ordinal_position;"
    ```

## Production Environment (Azure PostgreSQL)

**Production database changes must be handled with extreme care.**

### Credentials Management

Production database credentials (`DB-HOST`, `DB-NAME`, `DB-USER`, `DB-PASSWORD`) are stored securely in **Azure Key Vault**:
-   **Key Vault Name:** `ptchampion-kv` (as per project configuration)
-   **Secret Names (example):** `DB-HOST`, `DB-NAME`, `DB-USER`, `DB-PASSWORD`

The `DB_SSL_MODE` for Azure PostgreSQL connections **must be `require`**.

### Applying Migrations to Production (Recommended Method)

This method uses the `make migrate-up` command, which relies on environment variables for database connection details. You'll need to fetch these from Azure Key Vault first.

1.  **Ensure Azure CLI is Installed and Logged In:**
    ```bash
    az login
    ```
    Ensure the logged-in account has `Get` permissions for secrets in `ptchampion-kv`.

2.  **Fetch Secrets and Set Environment Variables:**
    In your terminal session, fetch each required secret and export it as an environment variable.
    ```bash
    export DB_HOST=$(az keyvault secret show --name DB-HOST --vault-name ptchampion-kv --query value -o tsv)
    export DB_NAME=$(az keyvault secret show --name DB-NAME --vault-name ptchampion-kv --query value -o tsv)
    export DB_USER=$(az keyvault secret show --name DB-USER --vault-name ptchampion-kv --query value -o tsv)
    export DB_PASSWORD=$(az keyvault secret show --name DB-PASSWORD --vault-name ptchampion-kv --query value -o tsv)
    export DB_PORT=5432 # Standard PostgreSQL port
    export DB_SSL_MODE=require
    ```
    Verify the variables are set: `echo $DB_HOST`, etc.

3.  **Apply Migrations:**
    Once the environment variables are correctly set with production values:
    ```bash
    make migrate-up
    ```
    This will apply any pending migrations from `sql/migrations/` to the production database. The `Makefile` has been configured to use the `sql/migrations` path and respect the `DB_SSL_MODE` variable.

### Applying Migrations via Direct `psql` (Use with Extreme Caution)

This method bypasses the `golang-migrate` tool's tracking. It should generally be avoided for schema migrations unless `make migrate-up` is encountering an unresolvable issue and a critical hotfix is needed. If used, ensure the migration files are still correctly versioned and committed.

1.  **Get Credentials:**
    As above, get the `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, and `DB_NAME` for production, ideally from Key Vault.

2.  **Run `psql`:**
    To apply a single migration file:
    ```bash
    PGPASSWORD='your_prod_password' psql \\
      "postgres://your_prod_user@your_prod_host:your_prod_port/your_prod_db?sslmode=require" \\
      -f sql/migrations/VERSION_descriptive_name.up.sql
    ```
    To run an ad-hoc command (like during troubleshooting):
    ```bash
    PGPASSWORD='your_prod_password' psql \\
      "postgres://your_prod_user@your_prod_host:your_prod_port/your_prod_db?sslmode=require" \\
      -c "ALTER TABLE your_table ADD COLUMN new_col TEXT;"
    ```
    **Warning:** Manually applied changes are not tracked by the migration tool and can lead to an inconsistent state in the `schema_migrations` table.

### Verifying Production Schema

Due to potential issues with CLI output in some environments (as observed during troubleshooting), the most reliable way to verify schema changes in production is often via:

1.  **Azure Portal's Query Editor:**
    -   Navigate to your Azure Database for PostgreSQL server (`ptchampion-db`).
    -   Use the "Query editor (preview)" if available.
    -   Login with production credentials (e.g., `dbadmin` and its password from Key Vault).
    -   Run your verification query (e.g., `SELECT column_name FROM information_schema.columns WHERE table_name = 'users';`).

2.  **GUI Database Client (DBeaver, pgAdmin):**
    -   Install a client like DBeaver or pgAdmin.
    -   Create a new connection using the production credentials obtained from Key Vault:
        -   **Host:** Value of `DB-HOST` secret
        -   **Port:** `5432`
        -   **Database:** Value of `DB-NAME` secret
        -   **Username:** Value of `DB-USER` secret (e.g., `dbadmin`)
        -   **Password:** Value of `DB-PASSWORD` secret
        -   **SSL Mode:** `require`
    -   Connect and browse the schema or run SQL queries.

    Example verification query:
    ```sql
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public' -- Or your specific schema if not 'public'
      AND table_name = 'users'    -- Replace 'users' with your table
    ORDER BY ordinal_position;
    ```

## Troubleshooting Migrations

-   **"No migration found for version X" or "File does not exist" errors:**
    This usually means the `golang-migrate` tool expects a pair of `.up.sql` and `.down.sql` files for a version it believes is applied (or partially applied) in the `schema_migrations` table, but one of the files is missing or misnamed.
    -   Ensure all migrations in `sql/migrations/` have both `.up.sql` and `.down.sql` files (even if the `.down.sql` is just a comment).
    -   Check the naming convention carefully (version prefix, underscore, name, suffix).

-   **"Dirty migration" errors:**
    This means a previous migration attempt failed part-way. The `schema_migrations` table in the database will mark the version as dirty. You may need to:
    1.  Manually fix the database schema to the state *before* the failed migration OR complete the failed migration's changes manually.
    2.  Manually update the `schema_migrations` table for that version (e.g., `UPDATE schema_migrations SET dirty = false WHERE version = X;`).
    3.  Alternatively, `golang-migrate` has a `force` command (`migrate force VERSION`) to tell the tool that a specific version should be considered applied (or not applied if version is -1). **Use `force` with extreme caution as it can lead to inconsistencies if not understood properly.**

-   **Authentication Failures:**
    -   Double-check credentials (username, password, host, database name).
    -   For Azure, ensure SSL mode is `require`.
    -   Verify Azure Key Vault secret names and that the CLI has permissions.
    -   Check Azure PostgreSQL firewall rules to ensure your IP is allowed to connect.

Always refer to the `golang-migrate/migrate` tool's documentation for more advanced troubleshooting. 