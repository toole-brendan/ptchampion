import { users, exercises, userExercises, type User, type InsertUser, type Exercise, type UserExercise, type InsertUserExercise, SEED_EXERCISES } from "@shared/schema";
import { db } from "./db";
import { eq, and, desc, inArray, sql } from "drizzle-orm";
import session from "express-session";
import connectPg from "connect-pg-simple";

const PostgresSessionStore = connectPg(session);

export interface IStorage {
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  updateUserLocation(userId: number, latitude: number, longitude: number): Promise<User>;
  
  // Exercise methods
  getExercises(): Promise<Exercise[]>;
  getExerciseById(id: number): Promise<Exercise | undefined>;
  initializeExercises(): Promise<Exercise[]>;
  
  // User Exercise methods
  getUserExercises(userId: number): Promise<UserExercise[]>;
  createUserExercise(userExercise: InsertUserExercise): Promise<UserExercise>;
  getUserExercisesByType(userId: number, type: string): Promise<UserExercise[]>;
  getLatestUserExercisesByType(userId: number): Promise<Record<string, UserExercise>>;
  
  // Leaderboard methods
  getGlobalLeaderboard(): Promise<any[]>;
  getLocalLeaderboard(latitude: number, longitude: number, radiusMiles: number): Promise<any[]>;
  
  sessionStore: ReturnType<typeof connectPg>;
}

export class DatabaseStorage implements IStorage {
  sessionStore: ReturnType<typeof connectPg>;
  
  constructor() {
    this.sessionStore = new PostgresSessionStore({ 
      conObject: {
        connectionString: process.env.DATABASE_URL,
      },
      createTableIfMissing: true 
    });
  }

  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user;
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user;
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const [user] = await db
      .insert(users)
      .values(insertUser)
      .returning();
    return user;
  }
  
  async updateUserLocation(userId: number, latitude: number, longitude: number): Promise<User> {
    const [user] = await db
      .update(users)
      .set({ 
        latitude: latitude.toString(), 
        longitude: longitude.toString() 
      })
      .where(eq(users.id, userId))
      .returning();
    return user;
  }
  
  async getExercises(): Promise<Exercise[]> {
    const exerciseList = await db.select().from(exercises);
    return exerciseList;
  }
  
  async getExerciseById(id: number): Promise<Exercise | undefined> {
    const [exercise] = await db.select().from(exercises).where(eq(exercises.id, id));
    return exercise;
  }
  
  async initializeExercises(): Promise<Exercise[]> {
    // Check if exercises already exist
    const existingExercises = await this.getExercises();
    
    if (existingExercises.length === 0) {
      // Seed the exercises
      const seededExercises = await db.insert(exercises).values(SEED_EXERCISES).returning();
      return seededExercises;
    }
    
    return existingExercises;
  }
  
  async getUserExercises(userId: number): Promise<UserExercise[]> {
    const userExerciseList = await db
      .select()
      .from(userExercises)
      .where(eq(userExercises.userId, userId))
      .orderBy(desc(userExercises.createdAt));
    return userExerciseList;
  }
  
  async createUserExercise(insertUserExercise: InsertUserExercise): Promise<UserExercise> {
    const [userExercise] = await db
      .insert(userExercises)
      .values(insertUserExercise)
      .returning();
    return userExercise;
  }
  
  async getUserExercisesByType(userId: number, type: string): Promise<UserExercise[]> {
    const exercisesOfType = await db
      .select()
      .from(exercises)
      .where(eq(exercises.type, type));
    
    const exerciseIds = exercisesOfType.map(exercise => exercise.id);
    
    if (exerciseIds.length === 0) return [];
    
    const userExerciseList = await db
      .select()
      .from(userExercises)
      .where(
        and(
          eq(userExercises.userId, userId),
          inArray(userExercises.exerciseId, exerciseIds),
          eq(userExercises.completed, true)
        )
      )
      .orderBy(desc(userExercises.createdAt));
    
    return userExerciseList;
  }
  
  async getLatestUserExercisesByType(userId: number): Promise<Record<string, UserExercise>> {
    const exerciseTypes = ["pushup", "pullup", "situp", "run"];
    const result: Record<string, UserExercise> = {};
    
    for (const type of exerciseTypes) {
      const exercises = await this.getUserExercisesByType(userId, type);
      if (exercises.length > 0) {
        result[type] = exercises[0];
      }
    }
    
    return result;
  }
  
  async getGlobalLeaderboard(): Promise<any[]> {
    // This is a simplified implementation - in a real app, you would calculate scores and join with users table
    const usersWithScores = await db.query.users.findMany({
      with: {
        userExercises: {
          where: eq(userExercises.completed, true),
          with: {
            exercise: true
          }
        }
      }
    });
    
    // Process and return leaderboard
    return this.processLeaderboardData(usersWithScores);
  }
  
  async getLocalLeaderboard(latitude: number, longitude: number, radiusMiles: number = 5): Promise<any[]> {
    // In a real implementation, you would use PostgreSQL's PostGIS extension
    // For simplicity, we'll get all users and filter by Haversine distance
    const allUsers = await db.query.users.findMany({
      with: {
        userExercises: {
          where: eq(userExercises.completed, true),
          with: {
            exercise: true
          }
        }
      }
    });
    
    // Filter users by distance
    const localUsers = allUsers.filter(user => {
      if (!user.latitude || !user.longitude) return false;
      
      const distance = this.haversineDistance(
        latitude, longitude,
        Number(user.latitude), Number(user.longitude)
      );
      
      return distance <= radiusMiles;
    });
    
    // Process and return leaderboard
    return this.processLeaderboardData(localUsers);
  }
  
  // Helper methods
  private haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 3958.8; // Radius of the Earth in miles
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) * 
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
    const distance = R * c;
    return distance;
  }
  
  private deg2rad(deg: number): number {
    return deg * (Math.PI/180);
  }
  
  private processLeaderboardData(usersWithExercises: any[]): any[] {
    return usersWithExercises.map(user => {
      // Calculate scores for each exercise type
      const pushupExercise = user.userExercises.filter((ue: any) => ue.exercise.type === 'pushup')
        .sort((a: any, b: any) => b.repetitions - a.repetitions)[0];
      
      const pullupExercise = user.userExercises.filter((ue: any) => ue.exercise.type === 'pullup')
        .sort((a: any, b: any) => b.repetitions - a.repetitions)[0];
      
      const situpExercise = user.userExercises.filter((ue: any) => ue.exercise.type === 'situp')
        .sort((a: any, b: any) => b.repetitions - a.repetitions)[0];
      
      const runExercise = user.userExercises.filter((ue: any) => ue.exercise.type === 'run')
        .sort((a: any, b: any) => a.timeInSeconds - b.timeInSeconds)[0];
      
      // Calculate overall score (simplified example)
      let overallScore = 0;
      let exerciseCount = 0;
      
      if (pushupExercise) {
        overallScore += pushupExercise.formScore || 0;
        exerciseCount++;
      }
      
      if (pullupExercise) {
        overallScore += pullupExercise.formScore || 0;
        exerciseCount++;
      }
      
      if (situpExercise) {
        overallScore += situpExercise.formScore || 0;
        exerciseCount++;
      }
      
      if (runExercise) {
        // Convert run time to a score (simplified)
        const runScore = Math.max(0, 100 - Math.floor(runExercise.timeInSeconds / 30));
        overallScore += runScore;
        exerciseCount++;
      }
      
      overallScore = exerciseCount > 0 ? Math.floor(overallScore / exerciseCount) : 0;
      
      return {
        id: user.id,
        username: user.username,
        overallScore,
        pushups: pushupExercise ? pushupExercise.repetitions : null,
        pullups: pullupExercise ? pullupExercise.repetitions : null,
        situps: situpExercise ? situpExercise.repetitions : null,
        runTime: runExercise ? this.formatRunTime(runExercise.timeInSeconds) : null,
        runTimeSeconds: runExercise ? runExercise.timeInSeconds : null
      };
    }).sort((a, b) => b.overallScore - a.overallScore);
  }
  
  private formatRunTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  }
}

export const storage = new DatabaseStorage();
