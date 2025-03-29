import * as dotenv from 'dotenv';
dotenv.config(); // Load environment variables from .env file

import express, { type Request, Response, NextFunction } from "express";
import cors from "cors"; // Import cors
import getPort from 'get-port'; // Import get-port
import { registerRoutes } from "./routes";
import { setupVite, serveStatic, log } from "./vite";

const app = express();

// Configure CORS - Use a very permissive configuration for development
app.use(cors({
  origin: '*', // Allow requests from any origin
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true, // Allow credentials (cookies, etc.)
  optionsSuccessStatus: 204 // Some legacy browsers choke on 204
}));

// Add CORS preflight handler for all routes
app.options('*', cors()); // Handle OPTIONS preflight requests

log("🔓 CORS configured to allow all origins, methods, and headers");

// Middleware for parsing JSON and urlencoded bodies
app.use(express.json());
app.use(express.urlencoded({ extended: false })); // Use false as per original code

// Logging Middleware (keeping the existing detailed logger)
app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      let logLine = `${req.method} ${path} ${res.statusCode} in ${duration}ms`;
      if (capturedJsonResponse) {
        logLine += ` :: ${JSON.stringify(capturedJsonResponse)}`;
      }

      if (logLine.length > 80) {
        logLine = logLine.slice(0, 79) + "…";
      }

      log(logLine);
    }
  });

  next();
});

// IIFE to handle async setup
(async () => {
  // Add middleware to manually add CORS headers to all responses as a fallback
  app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
    res.header('Access-Control-Allow-Credentials', 'true');
    
    // Handle preflight OPTIONS requests
    if (req.method === 'OPTIONS') {
      return res.status(204).end();
    }
    
    next();
  });

  // Register application routes (assuming this sets up session/passport internally or they are not needed here)
  const server = await registerRoutes(app);

  // Error Handling Middleware
  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    console.error("Unhandled Error:", err); // Log the full error
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";
    
    // Ensure CORS headers are set even for error responses
    res.header('Access-Control-Allow-Origin', '*');
    res.status(status).json({ message });
  });

  // Vite or Static File Serving
  if (app.get("env") === "development") {
    await setupVite(app, server); // Pass the HTTP server instance
  } else {
    serveStatic(app);
  }

  // Port Configuration and Server Start
  const basePort = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
  const port = await getPort({ port: basePort });

  // Listen using the server instance returned by registerRoutes
  server.listen({
    port,
    host: "0.0.0.0",
  }, () => {
    log(`🚀 Server ready at http://localhost:${port}`);
    log(`Frontend should connect to this backend.`);
    log(`CORS headers: Access-Control-Allow-Origin: *`);
  });

})(); // End IIFE