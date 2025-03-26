# PT Champion Backend Port Fix

## Issue Identified

The backend on the live site wasn't working due to a port mismatch between the server configuration and the Nginx/CloudFront setup:

1. In `server/index.ts`, the Express app was hardcoded to run on port 5000
2. However, in the Nginx configuration and CloudFront setup, API requests were being routed to port 3000
3. This mismatch resulted in the backend not receiving API requests, causing user registration and other backend features to fail

## Solution Implemented

We made the following change to fix the issue:

1. Modified `server/index.ts` to use the environment PORT variable (which is set to 3000 in `.env.production`) instead of the hardcoded port 5000:

```typescript
// Old code
const port = 5000;

// New code
const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
```

2. Created a deployment script (`fix-port-mismatch.sh`) to:
   - Build the application with the updated code
   - Copy the updated backend file to the EC2 instance
   - Restart the backend service
   - Create a CloudFront invalidation to ensure changes propagate quickly

## Verification Steps

After deploying the fix, verify that:

1. The backend is listening on port 3000
2. API requests are properly routed through Nginx
3. User registration and other backend functionality now work correctly

## Troubleshooting

If issues persist:

1. Check Nginx configuration on EC2 instance (`/etc/nginx/conf.d/ptchampion.conf`)
2. Wait for CloudFront invalidation to complete
3. Check backend logs: SSH into EC2 and run `pm2 logs ptchampion-api`

## Future Recommendations

1. Avoid hardcoding configuration values like port numbers
2. Use environment variables consistently across the application
3. Ensure all deployment configurations (Nginx, Docker, AWS) are aligned with application settings
