-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify extensions are enabled
SELECT 'pgcrypto extension:' as extension, 
       CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') 
            THEN 'enabled' 
            ELSE 'not enabled' 
       END as status
UNION ALL
SELECT 'postgis extension:', 
       CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') 
            THEN 'enabled' 
            ELSE 'not enabled' 
       END;