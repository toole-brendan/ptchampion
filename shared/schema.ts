import { pgTable, text, serial, integer, decimal, timestamp, boolean, json } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  email: text("email").notNull().unique(),
  firstName: text("first_name"),
  lastName: text("last_name"),
  passwordHash: text("password_hash").notNull(),
  displayName: text("display_name"),
  profilePictureUrl: text("profile_picture_url"),
  location: text("location"),
  latitude: decimal("latitude", { precision: 10, scale: 7 }),
  longitude: decimal("longitude", { precision: 10, scale: 7 }),
  lastSyncedAt: timestamp("last_synced_at").defaultNow(),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const exercises = pgTable("exercises", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  type: text("type").notNull(), // "pushup", "pullup", "situp", "run"
});

// New unified workouts table replacing user_exercises
export const workouts = pgTable("workouts", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  exerciseId: integer("exercise_id").notNull().references(() => exercises.id),
  exerciseType: text("exercise_type").notNull(), // Denormalized for performance
  repetitions: integer("repetitions"),
  durationSeconds: integer("duration_seconds"),
  distanceMeters: decimal("distance_meters", { precision: 10, scale: 2 }),
  formScore: integer("form_score").notNull().default(0), // 0-100, now required with default
  grade: integer("grade").notNull(), // 0-100 based on performance metrics
  isPublic: boolean("is_public").default(false),
  completedAt: timestamp("completed_at").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
  deviceId: text("device_id"), // ID of the device that created the workout
  metadata: json("metadata"), // JSON for additional exercise data (heart rate, pose analysis, etc.)
  notes: text("notes"), // User-provided notes
  syncStatus: text("sync_status").default('synced'), // synced, pending, conflict
});

// Keep user_exercises for backward compatibility during migration
export const userExercises = pgTable("user_exercises", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  exerciseId: integer("exercise_id").notNull().references(() => exercises.id),
  repetitions: integer("repetitions"),
  formScore: integer("form_score"), // 0-100
  timeInSeconds: integer("time_in_seconds"),
  grade: integer("grade"), // 0-100 based on performance metrics
  completed: boolean("completed").default(false),
  metadata: text("metadata"), // JSON string for additional exercise data
  deviceId: text("device_id"), // ID of the device that created the exercise record
  syncStatus: text("sync_status").default('synced'), // synced, pending, conflict
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Schema for inserting a new user
export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  email: true,
  firstName: true,
  lastName: true,
  passwordHash: true,
  displayName: true,
  profilePictureUrl: true,
  location: true,
  latitude: true,
  longitude: true,
});

// Schema for profile update
export const updateProfileSchema = createInsertSchema(users).pick({
  displayName: true,
  profilePictureUrl: true,
  location: true,
});

// Schema for inserting a new exercise
export const insertExerciseSchema = createInsertSchema(exercises);

// NEW: Schema for inserting workouts (replaces insertUserExerciseSchema)
export const insertWorkoutSchema = createInsertSchema(workouts).pick({
  userId: true,
  exerciseId: true,
  exerciseType: true,
  repetitions: true,
  durationSeconds: true,
  distanceMeters: true,
  formScore: true,
  grade: true,
  isPublic: true,
  completedAt: true,
  deviceId: true,
  metadata: true,
  notes: true,
  syncStatus: true,
}).extend({
  // Add validation for form_score range
  formScore: z.number().int().min(0).max(100).default(0),
  // Add validation for grade range  
  grade: z.number().int().min(0).max(100),
});

// Legacy schema for backward compatibility
export const insertUserExerciseSchema = createInsertSchema(userExercises).pick({
  userId: true,
  exerciseId: true,
  repetitions: true,
  formScore: true,
  timeInSeconds: true,
  grade: true,
  completed: true,
  metadata: true,
  deviceId: true,
  syncStatus: true,
});

// Types
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;
export type UpdateProfile = z.infer<typeof updateProfileSchema>;

export type Exercise = typeof exercises.$inferSelect;
export type InsertExercise = z.infer<typeof insertExerciseSchema>;

// NEW: Workout types
export type Workout = typeof workouts.$inferSelect;
export type InsertWorkout = z.infer<typeof insertWorkoutSchema>;

// Legacy types for backward compatibility
export type UserExercise = typeof userExercises.$inferSelect;
export type InsertUserExercise = z.infer<typeof insertUserExerciseSchema>;

// Updated sync types to use workouts
export type SyncRequest = {
  userId: number;
  deviceId: string;
  lastSyncTimestamp: string;
  data?: {
    workouts?: InsertWorkout[];
    userExercises?: InsertUserExercise[]; // Keep for backward compatibility
    profile?: UpdateProfile;
  };
};

export type SyncResponse = {
  success: boolean;
  timestamp: string;
  data?: {
    workouts?: Workout[];
    userExercises?: UserExercise[]; // Keep for backward compatibility
    profile?: User;
  };
  conflicts?: Workout[];
};

// Seed data for exercises
export const SEED_EXERCISES = [
  {
    name: "Push-ups",
    description: "Upper body exercise performed in a prone position, raising and lowering the body using the arms",
    type: "pushup",
  },
  {
    name: "Pull-ups",
    description: "Upper body exercise where you hang from a bar and pull your body up until your chin is above the bar",
    type: "pullup",
  },
  {
    name: "Sit-ups",
    description: "Abdominal exercise performed by lying on your back and lifting your torso",
    type: "situp",
  },
  {
    name: "2-mile Run",
    description: "Cardio exercise measuring endurance over a 2-mile distance",
    type: "run",
  },
];
