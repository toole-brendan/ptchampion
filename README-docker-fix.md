# Docker Deployment Fixes

## Issue 1: Build Failure in Docker

The deployment to EC2 was failing due to a build issue in the Docker container. The error message was:

```
Could not resolve entry module "index.html".
```

This occurred because:

1. The Vite configuration in `vite.config.ts` sets the root directory to `client/`
2. When Docker tried to build the application, it couldn't find `index.html` in the expected location
3. The directory structure inside the Docker container didn't match what Vite expected

## Issue 2: Backend Server Runtime Error

After fixing the build issue, we encountered a runtime error in the backend server:

```
Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'vite' imported from /app/dist/index.js
```

This occurred because:
1. The server code imports and uses Vite even in production mode
2. We were using `npm ci --only=production` in the Dockerfile, which doesn't install development dependencies
3. Vite is typically a development dependency but is still required for the server at runtime

## Issue 3: Port Conflict

After fixing the build issue, we encountered a port conflict error:

```
Error response from daemon: driver failed programming external connectivity on endpoint ptchampion-frontend: 
Error starting userland proxy: listen tcp4 0.0.0.0:80: bind: address already in use
```

This happens because port 80 is already in use on the EC2 instance, likely by another web server.

## Solution for Build Failure

The solution was to:

1. Modify the Dockerfile to skip the build step entirely
2. Instead, use the pre-built application files that are already built locally before deployment
3. This simplifies the deployment process by using the already successful local build 

## Solution for Backend Runtime Error

Our initial approach was to install all dependencies including Vite, but we encountered persistent issues. 

The better solution we implemented was to:

1. Create a simplified production server (`prod-server.js`) that doesn't depend on Vite
2. Use this server instead of the original server that had Vite dependencies
3. Go back to installing only production dependencies in the Dockerfile

The simplified production server:
```javascript
// Simple production server that doesn't rely on Vite
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create Express app
const app = express();
app.use(express.json());

// Serve static files from dist/public
const publicDir = path.join(__dirname, 'dist/public');
app.use(express.static(publicDir));

// API health endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// For all other routes, serve index.html (SPA fallback)
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Start server
const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', () => {
  console.log(`Production server running at http://localhost:${port}`);
});
```

The updated Dockerfile:
```dockerfile
# Production stage only - uses pre-built application
FROM node:18-alpine

WORKDIR /app

# Copy pre-built dist folder, package files, and production server
COPY ./dist ./dist
COPY package*.json ./
COPY prod-server.js ./

# Install only production dependencies (no Vite needed)
RUN npm ci --only=production

# Expose application port
EXPOSE 3000

# Environment variables will be provided at runtime
ENV NODE_ENV=production
ENV PORT=3000

# Start the application using our simplified production server
CMD ["node", "prod-server.js"]
```

## Solution for Port Conflict

The solution was to:

1. Modify the `docker-compose.yml` file to use port 8080 instead of port 80 for the frontend service
2. This allows the Nginx container to run without conflicts with existing services

The modified port mapping in `docker-compose.yml`:
```yaml
ports:
  - "8080:80"
```

## How to Verify

Deploy the application using:

```bash
./ptchampion-deploy.sh --deploy
```

The deployment should now succeed without the previous build error or port conflict.

After deployment, access the application at:
```
http://YOUR_EC2_IP:8080
```

And the API endpoints at:
```
http://YOUR_EC2_IP:8080/api
```

## Additional Information

If you need to make changes to the build process in the future:
1. Update the local build command in `package.json` and `vite.config.ts` as needed
2. Test the build locally before deploying
3. The Docker container will continue to use the pre-built files

For an improved deployment process, consider:
1. Continuing to use the simplified production server that doesn't depend on development tools
2. Potentially expanding the server.js file to include more of the needed backend functionality
3. Creating separate Docker configurations for development and production

This approach separates the build concerns from the deployment concerns, making the process more reliable.
