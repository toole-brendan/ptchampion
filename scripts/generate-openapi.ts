import { OpenApiGeneratorV3, OpenAPIRegistry } from '@asteasolutions/zod-to-openapi';
import * as yaml from 'js-yaml';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { z } from 'zod';
import { extendZodWithOpenApi } from '@asteasolutions/zod-to-openapi';

// Get current directory path in ES Modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Explicitly extend Zod with the .openapi() method
extendZodWithOpenApi(z);

// Import Drizzle schemas and Zod validation schemas
import {
  users,
  userExercises,
  insertUserSchema,
  updateProfileSchema,
  insertUserExerciseSchema,
} from '../shared/schema';
import { createSelectSchema } from 'drizzle-zod';

// --- Manually define Zod schemas mirroring Drizzle select types ---
// These need to be kept in sync manually if shared/schema.ts changes
const userSchema = z.object({
  id: z.number().int(),
  username: z.string(),
  // DO NOT include password in response schemas
  displayName: z.string().nullable(),
  profilePictureUrl: z.string().url().nullable(),
  location: z.string().nullable(),
  latitude: z.string().refine((val) => !isNaN(parseFloat(val)), { message: "Invalid latitude" }).nullable(), // Drizzle returns decimal as string
  longitude: z.string().refine((val) => !isNaN(parseFloat(val)), { message: "Invalid longitude" }).nullable(), // Drizzle returns decimal as string
  lastSyncedAt: z.date().nullable(), // Drizzle timestamp maps to Date
  createdAt: z.date().nullable(),
  updatedAt: z.date().nullable(),
}).openapi('User', { description: 'User profile information' });

const userExerciseSchema = z.object({
  id: z.number().int(),
  userId: z.number().int(),
  exerciseId: z.number().int(),
  repetitions: z.number().int().nullable(),
  formScore: z.number().int().min(0).max(100).nullable(),
  timeInSeconds: z.number().int().nullable(),
  grade: z.number().int().min(0).max(100).nullable(),
  completed: z.boolean(),
  metadata: z.string().nullable(), // Assuming metadata is stored as a JSON string
  deviceId: z.string().nullable(),
  syncStatus: z.enum(['synced', 'pending', 'conflict']).nullable(), // Use z.enum if applicable
  createdAt: z.date().nullable(),
  updatedAt: z.date().nullable(),
}).openapi('UserExercise', { description: 'Details of a completed or tracked exercise' });
// --- End of manually defined schemas ---


// Define Zod schemas for Sync types (approximated from TypeScript types)
// Use the manually defined userSchema/userExerciseSchema here
const syncRequestSchema = z.object({
  userId: z.number().int(),
  deviceId: z.string(),
  lastSyncTimestamp: z.string().datetime(), // Assuming ISO 8601 format
  data: z.object({
    userExercises: z.array(insertUserExerciseSchema).optional(), // Request uses Insert schema
    profile: updateProfileSchema.optional(), // Request uses Update schema
  }).optional(),
}).openapi('SyncRequest', { description: 'Request payload for synchronizing data'});

const syncResponseSchema = z.object({
  success: z.boolean(),
  timestamp: z.string().datetime(), // Assuming ISO 8601 format
  data: z.object({
    userExercises: z.array(userExerciseSchema).optional(), // Response uses Select schema
    profile: userSchema.optional(), // Response uses Select schema
  }).optional(),
  conflicts: z.array(userExerciseSchema).optional(), // Conflicts use Select schema
}).openapi('SyncResponse', { description: 'Response payload after data synchronization'});

// Add metadata directly to the imported Zod schemas
const insertUserWithMeta = insertUserSchema.openapi('InsertUser', { description: 'Data required to register a new user' });
const updateProfileWithMeta = updateProfileSchema.openapi('UpdateProfile', { description: 'Data for updating a user profile' });
const insertUserExerciseWithMeta = insertUserExerciseSchema.openapi('InsertUserExercise', { description: 'Data for recording a new user exercise attempt' });


const registry = new OpenAPIRegistry();

// Register all Zod schemas (manual and imported)
registry.register('User', userSchema);
registry.register('UserExercise', userExerciseSchema);
registry.register('InsertUser', insertUserWithMeta);
registry.register('UpdateProfile', updateProfileWithMeta);
registry.register('InsertUserExercise', insertUserExerciseWithMeta);
registry.register('SyncRequest', syncRequestSchema);
registry.register('SyncResponse', syncResponseSchema);

// --- Define API endpoints here using registry.registerPath({...}) ---
// Authentication endpoints
registry.registerPath({
  method: 'post',
  path: '/auth/register',
  summary: 'Register a new user',
  tags: ['Auth'],
  request: {
    body: {
      content: {
        'application/json': {
          schema: insertUserWithMeta,
        },
      },
    },
  },
  responses: {
    201: {
      description: 'User created successfully',
      content: {
        'application/json': {
          schema: userSchema,
        },
      },
    },
    400: {
      description: 'Invalid input (e.g., validation error)',
    },
    409: {
      description: 'Username already exists',
    },
    500: {
      description: 'Internal Server Error',
    }
  },
});

registry.registerPath({
  method: 'post',
  path: '/auth/login',
  summary: 'Authenticate a user and get JWT token',
  tags: ['Auth'],
  request: {
    body: {
      content: {
        'application/json': {
          schema: z.object({
            username: z.string().min(1),
            password: z.string().min(1),
          }).openapi('LoginRequest', { description: 'User credentials for login' }),
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Login successful',
      content: {
        'application/json': {
          schema: z.object({
            token: z.string(),
            user: userSchema,
          }).openapi('LoginResponse', { description: 'Authentication token and user profile' }),
        },
      },
    },
    400: {
      description: 'Invalid input',
    },
    401: {
      description: 'Invalid username or password',
    },
    500: {
      description: 'Internal Server Error',
    }
  },
});

// User Profile endpoints
registry.registerPath({
  method: 'patch',
  path: '/users/me',
  summary: 'Update current user profile',
  tags: ['Users'],
  security: [{ BearerAuth: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: z.object({
            username: z.string().min(3).max(30).optional(),
            display_name: z.string().max(100).optional(),
            profile_picture_url: z.string().url().optional(),
            location: z.string().max(100).optional(),
            latitude: z.number().optional(),
            longitude: z.number().optional(),
          }).openapi('UpdateUserRequest', { description: 'Fields to update in user profile' }),
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Profile updated successfully',
      content: {
        'application/json': {
          schema: userSchema,
        },
      },
    },
    400: {
      description: 'Invalid input',
    },
    401: {
      description: 'Unauthorized - missing or invalid token',
    },
    409: {
      description: 'Username already taken',
    },
    500: {
      description: 'Internal Server Error',
    }
  },
});

// Exercise endpoints
registry.registerPath({
  method: 'post',
  path: '/exercises',
  summary: 'Log a completed exercise',
  tags: ['Exercises'],
  security: [{ BearerAuth: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: z.object({
            exercise_id: z.number().int().positive(),
            reps: z.number().int().min(0).optional(),
            duration: z.number().int().min(0).optional(),
            distance: z.number().int().min(0).optional(),
            notes: z.string().optional(),
          }).openapi('LogExerciseRequest', { description: 'Exercise data to log' }),
        },
      },
    },
  },
  responses: {
    201: {
      description: 'Exercise logged successfully',
      content: {
        'application/json': {
          schema: z.object({
            id: z.number().int(),
            user_id: z.number().int(),
            exercise_id: z.number().int(),
            exercise_name: z.string(),
            exercise_type: z.string(),
            reps: z.number().int().optional(),
            time_in_seconds: z.number().int().optional(),
            distance: z.number().int().optional(),
            notes: z.string().optional(),
            grade: z.number().int(),
            created_at: z.string().datetime(),
          }).openapi('LogExerciseResponse', { description: 'Logged exercise data with calculated grade' }),
        },
      },
    },
    400: {
      description: 'Invalid input or missing required metrics for exercise type',
    },
    401: {
      description: 'Unauthorized - missing or invalid token',
    },
    500: {
      description: 'Internal Server Error',
    }
  },
});

registry.registerPath({
  method: 'get',
  path: '/exercises',
  summary: 'Get exercise history for the current user',
  tags: ['Exercises'],
  security: [{ BearerAuth: [] }],
  parameters: [
    {
      name: 'page',
      in: 'query',
      schema: {
        type: 'integer',
        default: 1,
        minimum: 1,
      },
      description: 'Page number for pagination',
      required: false,
    },
    {
      name: 'pageSize',
      in: 'query',
      schema: {
        type: 'integer',
        default: 20,
        minimum: 1,
        maximum: 100,
      },
      description: 'Number of items per page',
      required: false,
    },
  ],
  responses: {
    200: {
      description: 'Exercise history retrieved successfully',
      content: {
        'application/json': {
          schema: z.object({
            items: z.array(z.object({
              id: z.number().int(),
              user_id: z.number().int(),
              exercise_id: z.number().int(),
              exercise_name: z.string(),
              exercise_type: z.string(),
              reps: z.number().int().optional(),
              time_in_seconds: z.number().int().optional(),
              distance: z.number().int().optional(),
              notes: z.string().optional(),
              grade: z.number().int(),
              created_at: z.string().datetime(),
            })),
            total_count: z.number().int(),
            page: z.number().int(),
            page_size: z.number().int(),
          }).openapi('PaginatedExerciseHistoryResponse', { description: 'Paginated exercise history for user' }),
        },
      },
    },
    401: {
      description: 'Unauthorized - missing or invalid token',
    },
    500: {
      description: 'Internal Server Error',
    }
  },
});

// Leaderboard endpoints
registry.registerPath({
  method: 'get',
  path: '/leaderboard/{exerciseType}',
  summary: 'Get leaderboard for a specific exercise type',
  tags: ['Leaderboard'],
  parameters: [
    {
      name: 'exerciseType',
      in: 'path',
      schema: {
        type: 'string',
        enum: ['pushup', 'pullup', 'situp', 'run'],
      },
      description: 'Type of exercise for the leaderboard',
      required: true,
    },
    {
      name: 'limit',
      in: 'query',
      schema: {
        type: 'integer',
        default: 20,
        minimum: 1,
      },
      description: 'Maximum number of leaderboard entries to return',
      required: false,
    },
  ],
  responses: {
    200: {
      description: 'Leaderboard retrieved successfully',
      content: {
        'application/json': {
          schema: z.array(z.object({
            username: z.string(),
            display_name: z.string(),
            best_grade: z.number().int(),
          })).openapi('LeaderboardResponse', { description: 'Leaderboard entries with best scores' }),
        },
      },
    },
    400: {
      description: 'Invalid exercise type',
    },
    500: {
      description: 'Internal Server Error',
    }
  },
});

// Sync endpoints
registry.registerPath({
  method: 'post',
  path: '/sync',
  summary: 'Synchronize client data with the server',
  tags: ['Sync'],
  security: [{ BearerAuth: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: syncRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Sync successful',
      content: {
        'application/json': {
          schema: syncResponseSchema,
        },
      },
    },
    400: {
      description: 'Invalid sync request',
    },
    401: {
      description: 'Unauthorized - missing or invalid token',
    },
    500: {
      description: 'Internal Server Error during sync',
    }
  },
});

// Add API components for security (JWT Authentication)
registry.registerComponent('securitySchemes', 'BearerAuth', {
  type: 'http',
  scheme: 'bearer',
  bearerFormat: 'JWT',
  description: 'JWT token for authentication',
});

// Generate the OpenAPI specification
const generator = new OpenApiGeneratorV3(registry.definitions);

const openApiSpec = generator.generateDocument({
  openapi: '3.0.0',
  info: {
    version: '1.0.0',
    title: 'PT Champion API',
    description: 'API for the PT Champion fitness tracking application',
  },
  servers: [{ url: '/api/v1' }], // Adjust server URL as needed
});

// Write the specification to a YAML file
const yamlSpec = yaml.dump(openApiSpec);
const outputPath = path.resolve(__dirname, '../openapi.yaml');
fs.writeFileSync(outputPath, yamlSpec, { encoding: 'utf8' });

console.log(`✅ OpenAPI specification generated at ${outputPath}`); 