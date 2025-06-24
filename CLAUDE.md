# PT Champion Codebase Overview

## What is PT Champion?

PT Champion is a military fitness training application that uses computer vision to track and grade physical fitness exercises according to Army Physical Fitness Test (APFT) standards. The app provides real-time form feedback and scoring for push-ups, pull-ups, sit-ups, and 2-mile runs.

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Web Client    │     │   iOS Client    │     │ Android Client  │
│   (React/TS)    │     │    (Swift)      │     │   (Kotlin)      │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                         │
         └───────────────────────┴─────────────────────────┘
                                 │
                          ┌──────▼──────┐
                          │   Backend   │
                          │  (Go/Echo)  │
                          └──────┬──────┘
                                 │
                          ┌──────▼──────┐
                          │  PostgreSQL │
                          └─────────────┘
```

## Key Technologies

- **Backend**: Go with Echo framework, PostgreSQL, sqlc for type-safe SQL
- **Web**: React, TypeScript, MediaPipe for pose detection, Tailwind CSS
- **iOS**: Swift, MediaPipe for pose detection (uses Vision framework naming only)
- **Android**: Kotlin, CameraX, ML Kit
- **Infrastructure**: Docker, GitHub Actions CI/CD

## Project Structure

```
ptchampion/
├── web/                    # React web application
│   ├── src/
│   │   ├── grading/       # Exercise grading logic
│   │   ├── pages/         # React components/pages
│   │   ├── services/      # API and MediaPipe services
│   │   └── lib/           # Utilities and helpers
│   └── public/            # Static assets
│
├── ios/                   # iOS native app
│   └── ptchampion/
│       ├── Grading/       # Exercise grading logic
│       ├── Views/         # SwiftUI views
│       └── Models/        # Data models
│
├── android/               # Android native app
│   └── app/src/main/
│       ├── kotlin/        # Kotlin source code
│       └── res/           # Resources
│
├── internal/              # Go backend internal packages
│   ├── api/              # HTTP handlers
│   ├── auth/             # Authentication logic
│   ├── db/               # Database interactions
│   └── grading/          # Scoring logic
│
├── sql/                   # Database schema and queries
│   ├── schema/           # Table definitions
│   └── queries/          # sqlc queries
│
└── scripts/              # Build and deployment scripts
```

## Core Concepts

### 1. Exercise Types
The app supports 4 exercise types:
- **pushup**: Push-ups with form analysis
- **pullup**: Pull-ups with dead hang detection
- **situp**: Sit-ups with proper form validation
- **run**: 2-mile run with GPS tracking

### 2. Grading System
- **Grade**: APFT score (0-100) based on repetitions/time
- **Form Score**: Quality assessment (0-100) based on form analysis
- All grading happens **client-side** using computer vision
- Only final results are sent to the backend

### 3. Database Schema
Key tables:
- `users`: User accounts and profiles
- `exercises`: Exercise type definitions
- `workouts`: Completed workout sessions with grades
- `user_exercises`: Historical exercise data (legacy)

### 4. API Endpoints
Main endpoints:
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/workouts` - Log workout results
- `GET /api/leaderboard/:exerciseType` - Get leaderboard

## Key Files to Understand

### Backend
- `/cmd/server/main.go` - Entry point
- `/internal/api/handlers.go` - HTTP handlers
- `/internal/grading/constants.go` - Exercise constants
- `/internal/grading/rubrics.go` - APFT scoring tables
- `/sql/queries/exercise.sql` - Database queries

### Web Frontend
- `/web/src/grading/ExerciseGrader.ts` - Base grading interface
- `/web/src/grading/APFTScoring.ts` - Scoring tables
- `/web/src/grading/PushupAnalyzer.ts` - Push-up form analysis
- `/web/src/pages/exercises/PushupTracker.tsx` - Push-up UI
- `/web/src/services/MediaPipeService.ts` - Pose detection

### iOS
- `/ios/ptchampion/Grading/ExerciseGraderProtocol.swift` - Grading interface
- `/ios/ptchampion/Grading/APFTRepValidator.swift` - Rep validation logic
- `/ios/ptchampion/Grading/ScoreRubrics.swift` - Scoring tables
- `/ios/ptchampion/Services/PoseDetectorService.swift` - MediaPipe integration

## Exercise Grading Logic

### Client-Side Processing Flow
1. Camera captures video frames
2. MediaPipe extracts 33 pose landmarks (all platforms)
3. Analyzer calculates angles and positions
4. Grader determines exercise state and counts reps
5. Form score calculated based on deviations
6. Final APFT score calculated from rep count
7. Results sent to backend for storage

### Valid Rep Requirements

**Push-ups**:
- Start: Arms extended (>150°), body straight
- Bottom: Elbows ≤100°, maintain alignment
- Return: Full extension, complete range of motion

**Pull-ups**:
- Start: Dead hang (arms >160°)
- Top: Chin clears bar
- No kipping or excessive swinging

**Sit-ups**:
- Start: Shoulders on ground, knees at 90°
- Top: Torso vertical, elbows to knees
- Hands behind head throughout

## Common Tasks

### Adding a New Exercise Type
1. Add constant to `/internal/grading/constants.go`
2. Update OpenAPI spec enum in `/openapi.yaml`
3. Add scoring rubric to `/internal/grading/rubrics.go`
4. Create analyzer in `/web/src/grading/analyzers/`
5. Create grader in `/web/src/grading/graders/`
6. Add UI component in `/web/src/pages/exercises/`

### Running the Project
```bash
# Backend
cd ptchampion
go run cmd/server/main.go

# Web frontend
cd web
npm install
npm run dev

# Database
docker-compose up -d postgres
```

### Testing
```bash
# Backend tests
go test ./...

# Frontend tests
cd web && npm test

# E2E tests
cd web && npm run test:e2e
```

## Current State & Roadmap

### Completed
- ✅ Basic authentication system
- ✅ Exercise grading for 4 types
- ✅ Web app with MediaPipe integration
- ✅ iOS app with Vision framework
- ✅ Leaderboard functionality

### In Progress
- 🔄 Moving all grading logic to client-side (see LOCAL_GRADING_IMPLEMENTATION_PLAN.md)
- 🔄 Offline support for web app
- 🔄 Performance optimizations

### Planned
- 📋 Social features (follow users, share workouts)
- 📋 Training programs and goals
- 📋 Additional exercise types (plank, etc.)
- 📋 Multi-language support

## Important Notes

1. **Privacy First**: No video data leaves the device - all processing is local
2. **Military Standards**: Scoring follows official APFT/PFT guidelines
3. **Cross-Platform Consistency**: All platforms use MediaPipe and should produce identical scores
4. **Offline Capable**: Apps should work without internet (queue sync)
5. **Pose Detection**: All platforms use MediaPipe's BlazePose model for consistency

## Environment Variables

Backend (.env):
```
DATABASE_URL=postgresql://user:pass@localhost/ptchampion
JWT_SECRET=your-secret-key
PORT=8080
```

Web (.env.local):
```
VITE_API_URL=http://localhost:8080
```

## Debugging Tips

1. **MediaPipe not loading**: Check browser console for CORS issues
2. **Reps not counting**: Enable debug mode to see pose landmarks
3. **Database errors**: Check migrations are up to date
4. **Auth failures**: Verify JWT secret matches between restarts

## Contributing Guidelines

1. Keep grading logic on client-side only
2. Follow existing code patterns and styles
3. Add tests for new functionality
4. Update this file when adding major features
5. Use conventional commits for clear history

---

*Last updated: 2024-01-24*
*For detailed implementation plans, see LOCAL_GRADING_IMPLEMENTATION_PLAN.md*