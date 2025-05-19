# Synthetic Health Checks

PT Champion uses automated synthetic health checks to proactively monitor system health and detect potential issues before they affect users. This document explains how these checks work and how to configure them.

## Overview

The synthetic health checks are implemented as a GitHub Action that runs every 6 hours. These checks simulate real user interactions by:

1. Testing the `/healthz` endpoint to verify basic system availability
2. Authenticating with a test user account to obtain an auth token
3. Simulating a video upload to verify that the core functionality works

If any of these checks fail, an issue is automatically created in the GitHub repository to alert the team.

## Health Check Endpoints

The system provides two health-check endpoints:

- `/health`: Basic health check that returns a simple status
- `/healthz`: More comprehensive health check that includes component status, version information, and timestamps

### `/healthz` Response Example

```json
{
  "status": "healthy",
  "version": "1.0.3",
  "environment": "production",
  "timestamp": "2025-05-01T12:34:56Z",
  "components": {
    "api": "healthy",
    "database": "healthy",
    "storage": "healthy"
  }
}
```

## Configuration

### GitHub Action Configuration

The health check GitHub Action is configured in the `.github/workflows/health-check.yml` file. Key configuration options include:

- **Schedule**: By default, health checks run every 6 hours. This can be adjusted by modifying the cron expression.
- **Environments**: Health checks can target different environments (dev, staging, production).
- **API Endpoints**: The base URLs for different environments can be configured in the workflow file.

### Test Accounts

The health checks require test user accounts to authenticate with the system. These accounts should:

1. Be dedicated specifically for health checks
2. Have minimal permissions required for testing
3. Not contain any real user data

Test account credentials are stored as GitHub secrets:

- `HEALTH_CHECK_TEST_USERNAME` and `HEALTH_CHECK_TEST_PASSWORD` for dev/staging environments
- `HEALTH_CHECK_PROD_USERNAME` and `HEALTH_CHECK_PROD_PASSWORD` for production environment

## Running Health Checks Manually

You can manually trigger health checks from the GitHub Actions tab:

1. Navigate to the "Actions" tab in the GitHub repository
2. Select the "Synthetic Health Check" workflow
3. Click "Run workflow"
4. Select the target environment from the dropdown
5. Click "Run workflow" to start the checks

## Alerts and Notifications

When a health check fails:

1. The GitHub Action will exit with a non-zero status code
2. A GitHub issue will be automatically created with the "bug", "automated", and "health-check" labels
3. The issue will contain details about which check failed and in which environment

## Extending Health Checks

To add additional checks to the synthetic health check workflow:

1. Update the `/healthz` endpoint to include checks for new components
2. Add new steps to the GitHub Action workflow to test additional functionality
3. Update the test accounts if additional permissions are required

## Troubleshooting

Common issues with health checks include:

- **Invalid credentials**: Ensure that the test account credentials are correctly set in GitHub secrets
- **Endpoint URL changes**: If API endpoints change, update the base URLs in the workflow file
- **Timeouts**: If requests consistently time out, check network connectivity or increase the timeout values in the curl commands

If health checks are consistently failing, manually verify the system status and test the API endpoints directly. 