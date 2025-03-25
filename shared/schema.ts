import { pgTable, text, serial, integer, decimal, timestamp, boolean, json } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  location: text("location"),
  latitude: decimal("latitude", { precision: 10, scale: 7 }),
  longitude: decimal("longitude", { precision: 10, scale: 7 }),
  createdAt: timestamp("created_at").defaultNow(),
});

export const exercises = pgTable("exercises", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  type: text("type").notNull(), // "pushup", "pullup", "situp", "run"
});

export const userExercises = pgTable("user_exercises", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  exerciseId: integer("exercise_id").notNull().references(() => exercises.id),
  repetitions: integer("repetitions"),
  formScore: integer("form_score"), // 0-100
  timeInSeconds: integer("time_in_seconds"),
  completed: boolean("completed").default(false),
  metadata: text("metadata"), // JSON string for additional exercise data (distance, heart rate, etc.)
  createdAt: timestamp("created_at").defaultNow(),
});

// Schema for inserting a new user
export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  password: true,
  location: true,
  latitude: true,
  longitude: true,
});

// Schema for inserting a new exercise
export const insertExerciseSchema = createInsertSchema(exercises);

// Schema for inserting a new user exercise
export const insertUserExerciseSchema = createInsertSchema(userExercises).pick({
  userId: true,
  exerciseId: true,
  repetitions: true,
  formScore: true,
  timeInSeconds: true,
  completed: true,
  metadata: true,
});

// Types
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;

export type Exercise = typeof exercises.$inferSelect;
export type InsertExercise = z.infer<typeof insertExerciseSchema>;

export type UserExercise = typeof userExercises.$inferSelect;
export type InsertUserExercise = z.infer<typeof insertUserExerciseSchema>;

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
