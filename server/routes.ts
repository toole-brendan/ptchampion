import type { Express, Request, Response, NextFunction } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { setupAuth } from "./auth";
import { z } from "zod";
import { insertUserExerciseSchema } from "@shared/schema";
import passport from "passport";

// Custom middleware that checks for both session and JWT authentication
const authenticate = async (req: Request, res: Response, next: NextFunction) => {
  // First check for session auth
  if (req.isAuthenticated()) {
    return next();
  }
  
  // If not authenticated by session, check for JWT
  return passport.authenticate('jwt', { session: false })(req, res, next);
};

export async function registerRoutes(app: Express): Promise<Server> {
  // Set up authentication routes
  setupAuth(app);
  
  // Initialize exercises on startup
  await storage.initializeExercises();

  // Get all exercises - publicly accessible
  app.get("/api/exercises", async (req, res, next) => {
    try {
      const exercises = await storage.getExercises();
      res.json(exercises);
    } catch (err) {
      next(err);
    }
  });
  
  // Get exercise by ID - publicly accessible
  app.get("/api/exercises/:id", async (req, res, next) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: "Invalid exercise ID" });
      }
      
      const exercise = await storage.getExerciseById(id);
      if (!exercise) {
        return res.status(404).json({ message: "Exercise not found" });
      }
      
      res.json(exercise);
    } catch (err) {
      next(err);
    }
  });
  
  // Get user exercises - protected
  app.get("/api/user-exercises", authenticate, async (req, res, next) => {
    try {
      // Ensure user is defined
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }
      
      const userExercises = await storage.getUserExercises(req.user.id);
      res.json(userExercises);
    } catch (err) {
      next(err);
    }
  });
  
  // Get user exercises by type - protected
  app.get("/api/user-exercises/:type", authenticate, async (req, res, next) => {
    try {
      // Ensure user is defined
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }
      
      const { type } = req.params;
      const validTypes = ["pushup", "pullup", "situp", "run"];
      
      if (!validTypes.includes(type)) {
        return res.status(400).json({ message: "Invalid exercise type" });
      }
      
      const userExercises = await storage.getUserExercisesByType(req.user.id, type);
      res.json(userExercises);
    } catch (err) {
      next(err);
    }
  });
  
  // Get latest exercise results for each type - protected
  app.get("/api/user-exercises/latest/all", authenticate, async (req, res, next) => {
    try {
      // Ensure user is defined
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }
      
      const latestExercises = await storage.getLatestUserExercisesByType(req.user.id);
      res.json(latestExercises);
    } catch (err) {
      next(err);
    }
  });
  
  // Create user exercise - protected
  app.post("/api/user-exercises", authenticate, async (req, res, next) => {
    try {
      // Ensure user is defined
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }
      
      const userExerciseData = insertUserExerciseSchema.parse({
        ...req.body,
        userId: req.user.id
      });
      
      const userExercise = await storage.createUserExercise(userExerciseData);
      res.status(201).json(userExercise);
    } catch (err) {
      if (err instanceof z.ZodError) {
        return res.status(400).json({ message: "Invalid data", errors: err.errors });
      }
      next(err);
    }
  });
  
  // Get global leaderboard - publicly accessible
  app.get("/api/leaderboard/global", async (req, res, next) => {
    try {
      const leaderboard = await storage.getGlobalLeaderboard();
      res.json(leaderboard);
    } catch (err) {
      next(err);
    }
  });
  
  // Get local leaderboard - publicly accessible
  app.get("/api/leaderboard/local", async (req, res, next) => {
    try {
      const latitude = parseFloat(req.query.latitude as string);
      const longitude = parseFloat(req.query.longitude as string);
      const radius = parseInt(req.query.radius as string) || 5;
      
      if (isNaN(latitude) || isNaN(longitude)) {
        return res.status(400).json({ message: "Invalid coordinates" });
      }
      
      const leaderboard = await storage.getLocalLeaderboard(latitude, longitude, radius);
      res.json(leaderboard);
    } catch (err) {
      next(err);
    }
  });

  // Synchronization endpoint for mobile clients
  app.post("/api/sync", authenticate, async (req, res, next) => {
    try {
      // Ensure user is defined
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }
      
      const { deviceId, lastSyncTimestamp, data } = req.body;
      
      if (!deviceId || !lastSyncTimestamp) {
        return res.status(400).json({ 
          message: "Missing required sync parameters",
          requiredParams: ['deviceId', 'lastSyncTimestamp']
        });
      }
      
      const syncRequest = {
        userId: req.user.id,
        deviceId,
        lastSyncTimestamp,
        data
      };
      
      const syncResponse = await storage.syncUserData(syncRequest);
      res.json(syncResponse);
    } catch (err) {
      next(err);
    }
  });
  
  // Profile update endpoint
  app.post("/api/profile", authenticate, async (req, res, next) => {
    try {
      // Ensure user is defined
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }
      
      const profileData = req.body;
      const updatedUser = await storage.updateUserProfile(req.user.id, profileData);
      res.json(updatedUser);
    } catch (err) {
      next(err);
    }
  });
  
  // API health check endpoint - useful for mobile clients to verify connectivity
  app.get("/api/health", (req, res) => {
    res.json({ 
      status: "ok", 
      timestamp: new Date().toISOString(),
      version: "1.0"
    });
  });

  const httpServer = createServer(app);
  return httpServer;
}
