import { users, exercises, userExercises, type User, type InsertUser, type Exercise, type UserExercise, type InsertUserExercise, type UpdateProfile, type SyncRequest, type SyncResponse, SEED_EXERCISES } from "@shared/schema";
import { db } from "./db";
import { eq, and, desc, inArray, sql, gt, or } from "drizzle-orm";
import session from "express-session";
import connectPg from "connect-pg-simple";

const PostgresSessionStore = connectPg(session);

export interface IStorage {
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  updateUserLocation(userId: number, latitude: number, longitude: number): Promise<User>;
  updateUserProfile(userId: number, profileData: UpdateProfile): Promise<User>;

  // Exercise methods
  getExercises(): Promise<Exercise[]>;
  getExerciseById(id: number): Promise<Exercise | undefined>;
  initializeExercises(): Promise<Exercise[]>;

  // User Exercise methods
  getUserExercises(userId: number): Promise<UserExercise[]>;
  createUserExercise(userExercise: InsertUserExercise): Promise<UserExercise>;
  getUserExercisesByType(userId: number, type: string): Promise<UserExercise[]>;
  getLatestUserExercisesByType(userId: number): Promise<Record<string, UserExercise>>;
  getUserExercisesSince(userId: number, since: Date): Promise<UserExercise[]>;

  // Sync methods
  syncUserData(syncRequest: SyncRequest): Promise<SyncResponse>;
  updateLastSynced(userId: number): Promise<void>;

  // Leaderboard methods
  getGlobalLeaderboard(): Promise<any[]>;
  getLocalLeaderboard(latitude: number, longitude: number, radiusMiles: number): Promise<any[]>;

  sessionStore: session.Store; // Use session.Store for consistency
}

export class DatabaseStorage implements IStorage {
  sessionStore: session.Store;

  constructor() {
    // Instantiate the store correctly
    this.sessionStore = new PostgresSessionStore({
      conObject: {
        connectionString: process.env.DATABASE_URL,
      },
      tableName: 'session',
      createTableIfMissing: true
    });
  }

  async getUser(id: number): Promise<User | undefined> {
    try {
      // Check if id is valid
      if (id === undefined || id === null) {
        console.error("Invalid user id:", id);
        return undefined;
      }

      // Use Drizzle's query builder
      const userResult = await db
        .select()
        .from(users)
        .where(eq(users.id, id))
        .limit(1);

      if (userResult.length === 0) {
        return undefined;
      }

      // Add default fallbacks for potentially missing columns
      const user = userResult[0];
      return {
        ...user,
        displayName: user.displayName || user.username,
        profilePictureUrl: user.profilePictureUrl || null,
        lastSyncedAt: user.lastSyncedAt || new Date(),
        updatedAt: user.updatedAt || new Date(),
      };
    } catch (error) {
      console.error("Error getting user:", error);
      return undefined;
    }
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    try {
      // Use Drizzle's query builder for type safety
      const userResult = await db
        .select()
        .from(users)
        .where(eq(users.username, username))
        .limit(1);

      if (userResult.length === 0) {
        return undefined;
      }

      // Drizzle returns the correctly typed object directly
      // We might still need default fallbacks if columns were added after user creation
      const user = userResult[0];
      return {
        ...user,
        displayName: user.displayName || user.username, // Fallback for display name
        profilePictureUrl: user.profilePictureUrl || null,
        lastSyncedAt: user.lastSyncedAt || new Date(),
        updatedAt: user.updatedAt || new Date(),
      };
    } catch (error) {
      console.error("Error getting user by username:", error);
      return undefined;
    }
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
        longitude: longitude.toString(),
        updatedAt: new Date()
      })
      .where(eq(users.id, userId))
      .returning();
    return user;
  }

  async updateUserProfile(userId: number, profileData: UpdateProfile): Promise<User> {
    // Get existing user to handle backward compatibility with non-existent columns
    const existingUser = await this.getUser(userId);
    if (!existingUser) {
      throw new Error("User not found");
    }

    // Try to update only fields that can safely be updated
    try {
      const [user] = await db
        .update(users)
        .set({
          ...profileData,
          updatedAt: new Date()
        })
        .where(eq(users.id, userId))
        .returning();
      return user;
    } catch (error) {
      // If the update fails due to missing columns, we'll return the existing user
      console.error("Error updating user profile:", error);
      return existingUser;
    }
  }

  async getUserExercisesSince(userId: number, since: Date): Promise<UserExercise[]> {
    try {
      const userExerciseList = await db
        .select()
        .from(userExercises)
        .where(
          and(
            eq(userExercises.userId, userId),
            gt(userExercises.createdAt, since)
          )
        )
        .orderBy(desc(userExercises.createdAt));
      return userExerciseList;
    } catch (error) {
      // If we can't get exercises with the updated schema, return empty array
      console.error("Error getting exercises since date:", error);
      return [];
    }
  }

  async updateLastSynced(userId: number): Promise<void> {
    try {
      await db
        .update(users)
        .set({
          lastSyncedAt: new Date()
        })
        .where(eq(users.id, userId));
    } catch (error) {
      console.error("Error updating last synced timestamp:", error);
    }
  }

  async syncUserData(syncRequest: SyncRequest): Promise<SyncResponse> {
    const { userId, deviceId, lastSyncTimestamp, data } = syncRequest;
    const lastSyncDate = new Date(lastSyncTimestamp);
    const now = new Date();

    // Initialize response with empty arrays to avoid undefined errors
    const response: SyncResponse = {
      success: true,
      timestamp: now.toISOString(),
      data: {
        userExercises: [],
        profile: undefined
      },
      conflicts: []
    };

    try {
      // 1. Get user profile
      const user = await this.getUser(userId);
      if (!user) {
        return {
          success: false,
          timestamp: now.toISOString(),
          data: {
            userExercises: [],
            profile: undefined
          },
          conflicts: []
        };
      }

      // 2. Update user profile if provided
      if (data?.profile) {
        const updatedUser = await this.updateUserProfile(userId, data.profile);
        if (response.data) {
          response.data.profile = updatedUser;
        }
      } else if (response.data) {
        response.data.profile = user;
      }

      const syncedExercises: UserExercise[] = [];

      // 3. Process incoming exercise data
      if (data?.userExercises && data.userExercises.length > 0) {
        for (const exercise of data.userExercises) {
          try {
            // Ensure userId matches the authenticated user
            const exerciseWithUserId = {
              ...exercise,
              userId: userId
            };

            const result = await this.createUserExercise(exerciseWithUserId);
            syncedExercises.push(result);
          } catch (error) {
            console.error("Error syncing exercise:", error);
          }
        }
      }

      // 4. Get exercises since last sync
      const serverExercises = await this.getUserExercisesSince(userId, lastSyncDate);

      // 5. Add all synced exercises to response
      if (response.data) {
        response.data.userExercises = [
          ...syncedExercises,
          ...serverExercises
        ];
      }

      // 6. Try to update last synced timestamp - gracefully handle if column doesn't exist
      try {
        await db.execute(
          sql`UPDATE users SET updated_at = NOW() WHERE id = ${userId}`
        );
      } catch (error) {
        console.error("Error updating timestamp:", error);
      }

      return response;
    } catch (error) {
      console.error("Sync error:", error);
      return {
        success: false,
        timestamp: now.toISOString(),
        data: {
          userExercises: [],
          profile: undefined
        },
        conflicts: []
      };
    }
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
    try {
      // Prepare values for insertion, ensuring correct types and defaults
      const valuesToInsert = {
        ...insertUserExercise, // Spread the input values (should match schema keys)
        // Ensure metadata is stringified if it's an object
        metadata: typeof insertUserExercise.metadata === 'object' && insertUserExercise.metadata !== null
                  ? JSON.stringify(insertUserExercise.metadata)
                  : insertUserExercise.metadata,
        // Ensure optional fields have defaults if not provided
        repetitions: insertUserExercise.repetitions ?? null,
        formScore: insertUserExercise.formScore ?? null,
        timeInSeconds: insertUserExercise.timeInSeconds ?? null,
        grade: insertUserExercise.grade ?? null,
        completed: insertUserExercise.completed ?? false,
        deviceId: insertUserExercise.deviceId ?? null,
        syncStatus: insertUserExercise.syncStatus ?? 'synced',
        updatedAt: new Date() // Set updatedAt timestamp
      };

      // Use Drizzle's insert and returning for type safety
      const [newUserExercise] = await db
        .insert(userExercises)
        .values(valuesToInsert) // Pass the prepared object
        .returning();

      // Drizzle returns the correctly typed object
      // Parse metadata back if needed immediately
      return {
        ...newUserExercise,
        metadata: typeof newUserExercise.metadata === 'string'
                  ? JSON.parse(newUserExercise.metadata)
                  : newUserExercise.metadata
      };
    } catch (error) {
      console.error("Error creating user exercise:", error);
      throw error;
    }
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
    // This is a simplified implementation - in a real app, you would calculate scores
    const usersResult = await db.select().from(users);
    const userExercisesResult = await db
      .select()
      .from(userExercises)
      .where(eq(userExercises.completed, true));
    const exercisesResult = await db.select().from(exercises);

    // Manually join the data
    const usersWithScores = usersResult.map(user => {
      const userExs = userExercisesResult.filter(ue => ue.userId === user.id);

      return {
        ...user,
        userExercises: userExs.map(ue => {
          const exercise = exercisesResult.find(e => e.id === ue.exerciseId);
          return {
            ...ue,
            exercise
          };
        })
      };
    });

    // Process the leaderboard data
    const processedLeaderboard = this.processLeaderboardData(usersWithScores);

    // Return up to 100 users for the global leaderboard
    return processedLeaderboard.slice(0, 100);
  }

  async getLocalLeaderboard(latitude: number, longitude: number, radiusMiles: number = 5): Promise<any[]> {
    // In a real implementation, you would use PostgreSQL's PostGIS extension
    const usersResult = await db.select().from(users);
    const userExercisesResult = await db
      .select()
      .from(userExercises)
      .where(eq(userExercises.completed, true));
    const exercisesResult = await db.select().from(exercises);

    // Manually join the data
    const allUsers = usersResult.map(user => {
      const userExs = userExercisesResult.filter(ue => ue.userId === user.id);

      return {
        ...user,
        userExercises: userExs.map(ue => {
          const exercise = exercisesResult.find(e => e.id === ue.exerciseId);
          return {
            ...ue,
            exercise
          };
        })
      };
    });

    // Filter users by distance
    const localUsers = allUsers.filter(user => {
      if (!user.latitude || !user.longitude) return false;

      const distance = this.haversineDistance(
        latitude, longitude,
        Number(user.latitude), Number(user.longitude)
      );

      // Only include users within the specified radius (default 5 miles)
      return distance <= radiusMiles;
    });

    // Process the leaderboard data
    const processedLeaderboard = this.processLeaderboardData(localUsers);

    // Return up to 100 users for the local leaderboard
    return processedLeaderboard.slice(0, 100);
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
