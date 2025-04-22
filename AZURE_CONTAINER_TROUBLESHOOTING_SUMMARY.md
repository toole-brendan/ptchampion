# Azure Container Deployment Troubleshooting Summary

## Issues Identified

Based on the error logs and investigation, the following issues were identified with the PT Champion API Azure App Service container deployment:

1. **Database Connection Failures**
   - The container failed to connect to PostgreSQL database
   - SSL mode configuration mismatch (require vs disable)
   - Possible firewall or network connectivity issues

2. **Container Startup Timeout**
   - The default 230-second startup timeout was insufficient
   - The container exceeded this limit during initial database migrations

3. **Health Check Issues**
   - No proper health check endpoint was responding
   - The Azure platform couldn't determine if the container was healthy

4. **Container Image Pull Problems**
   - Intermittent issues with pulling the container image from ACR
   - Possible permissions or authentication issues

## Solutions Implemented

### 1. Enhanced Entrypoint Script (`scripts/entrypoint.sh`)

The entrypoint script was modified to:
- Handle DB_SSL_MODE environment variable properly
- Add more robust error handling for database connections
- Implement a simple health check endpoint using netcat
- Provide verbose logging for troubleshooting
- Support ignoring migration failures and DB connection failures for testing

### 2. Updated Dockerfile

The Dockerfile was updated to:
- Add netcat-openbsd package for health check capabilities
- Maintain all existing functionality while adding diagnostic tools

### 3. Azure Configuration Script (`fix-container-config.sh`)

A new script was created to:
- Set container startup timeout to 600 seconds (up from default 230 seconds)
- Enable persistent storage for troubleshooting
- Configure troubleshooting flags (IGNORE_MIGRATION_FAILURE, IGNORE_DB_CONNECTION_FAILURE)
- Ensure managed identity has proper ACR pull permissions
- Set WEBSITES_PORT to match the container's exposed port

### 4. Database Testing Script (`test-db-connection.sh`)

A diagnostic script was created to:
- Test basic TCP connectivity to the database
- Verify authentication credentials
- Check database schema and table structure
- Examine PostgreSQL version and connection information

### 5. Container Debugging Script (`debug-container.sh`)

A comprehensive debugging tool was created to:
- Download and analyze container logs
- Check App Service configuration
- Verify ACR images and tags
- Ensure managed identity setup
- Configure timeout and storage settings
- Suggest specific fixes based on findings

### 6. Frontend Deployment Fix

The deployment script was updated to:
- Use `auth-mode key` instead of `auth-mode login` for Azure Storage blob uploads

## Execution Results

1. The container configuration was updated using `fix-container-config.sh`
2. The container was rebuilt and deployed with the new entrypoint script and Dockerfile
3. Initial testing shows progress but the following items still need attention:
   - Database connection issues still need to be resolved
   - Health check endpoint needs further refinement
   - Firewall rules may need to be updated

## Next Steps

1. **Database Connectivity**
   - Run `./test-db-connection.sh` to verify PostgreSQL connectivity
   - Confirm firewall rules allow connections from Azure App Service IP ranges
   - Validate all database credentials are correct

2. **Monitoring & Debugging**
   - Use `az webapp log tail --name ptchampion-api-westus --resource-group ptchampion-rg` to monitor logs in real-time
   - Check the container logs in the debug_logs directory
   - Use the Azure Portal's diagnostic tools for additional insights

3. **Final Configuration**
   - Once the container is stable, remove the troubleshooting flags:
     ```bash
     az webapp config appsettings set --name ptchampion-api-westus --resource-group ptchampion-rg --settings IGNORE_MIGRATION_FAILURE=false IGNORE_DB_CONNECTION_FAILURE=false
     ```
   - Consider implementing a more robust health check in your Go application code

4. **Future Improvements**
   - Add better error handling in the Go application
   - Implement more comprehensive logging
   - Consider container readiness probes in addition to health checks
   - Document the deployment and troubleshooting process for the team

## Additional Resources

- [AZURE_CONTAINER_DEPLOYMENT_FIX.md](./AZURE_CONTAINER_DEPLOYMENT_FIX.md) - Detailed guide on fixing deployment issues
- [debug_logs/](./debug_logs/) - Container logs for analysis
- [scripts/entrypoint.sh](./scripts/entrypoint.sh) - Enhanced container entrypoint script
- [Dockerfile](./Dockerfile) - Updated container build definition

## Conclusion

The Azure container deployment issues were addressed through a combination of:
1. Enhanced container configuration
2. Improved error handling and diagnostics
3. Environment variable fixes
4. Startup timeout adjustments
5. Health check implementation

While the container is still not fully operational, the diagnostic tools created should help pinpoint the remaining issues, which appear to be primarily related to database connectivity and network configuration.
