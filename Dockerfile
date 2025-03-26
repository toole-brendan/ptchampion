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
