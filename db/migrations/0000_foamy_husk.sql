CREATE TABLE "exercises" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"type" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_exercises" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" integer NOT NULL,
	"exercise_id" integer NOT NULL,
	"repetitions" integer,
	"form_score" integer,
	"time_in_seconds" integer,
	"grade" integer,
	"completed" boolean DEFAULT false,
	"metadata" text,
	"device_id" text,
	"sync_status" text DEFAULT 'synced',
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" serial PRIMARY KEY NOT NULL,
	"username" text NOT NULL,
	"password" text NOT NULL,
	"display_name" text,
	"profile_picture_url" text,
	"location" text,
	"latitude" numeric(10, 7),
	"longitude" numeric(10, 7),
	"last_synced_at" timestamp DEFAULT now(),
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "users_username_unique" UNIQUE("username")
);
--> statement-breakpoint
ALTER TABLE "user_exercises" ADD CONSTRAINT "user_exercises_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_exercises" ADD CONSTRAINT "user_exercises_exercise_id_exercises_id_fk" FOREIGN KEY ("exercise_id") REFERENCES "public"."exercises"("id") ON DELETE no action ON UPDATE no action;