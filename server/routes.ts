import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { setupAuth } from "./auth";
import { z } from "zod";
import { insertUserExerciseSchema } from "@shared/schema";

export async function registerRoutes(app: Express): Promise<Server> {
  // Set up authentication routes
  setupAuth(app);
  
  // Initialize exercises on startup
  await storage.initializeExercises();

  // Get all exercises
  app.get("/api/exercises", async (req, res, next) => {
    try {
      const exercises = await storage.getExercises();
      res.json(exercises);
    } catch (err) {
      next(err);
    }
  });
  
  // Get exercise by ID
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
  
  // Get user exercises
  app.get("/api/user-exercises", async (req, res, next) => {
    if (!req.isAuthenticated()) return res.sendStatus(401);
    
    try {
      const userExercises = await storage.getUserExercises(req.user.id);
      res.json(userExercises);
    } catch (err) {
      next(err);
    }
  });
  
  // Get user exercises by type
  app.get("/api/user-exercises/:type", async (req, res, next) => {
    if (!req.isAuthenticated()) return res.sendStatus(401);
    
    try {
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
  
  // Get latest exercise results for each type
  app.get("/api/user-exercises/latest/all", async (req, res, next) => {
    if (!req.isAuthenticated()) return res.sendStatus(401);
    
    try {
      const latestExercises = await storage.getLatestUserExercisesByType(req.user.id);
      res.json(latestExercises);
    } catch (err) {
      next(err);
    }
  });
  
  // Create user exercise
  app.post("/api/user-exercises", async (req, res, next) => {
    if (!req.isAuthenticated()) return res.sendStatus(401);
    
    try {
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
  
  // Get global leaderboard
  app.get("/api/leaderboard/global", async (req, res, next) => {
    try {
      const leaderboard = await storage.getGlobalLeaderboard();
      res.json(leaderboard);
    } catch (err) {
      next(err);
    }
  });
  
  // Get local leaderboard
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

  const httpServer = createServer(app);
  return httpServer;
}
