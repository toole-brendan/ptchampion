<pt_champion>

<project_overview>
PT Champion is a cross-platform fitness application that leverages computer vision to help users track workouts and improve their exercise form. It uses a device's camera and sensors to analyze exercises like push-ups in real time – counting repetitions and grading form via AI. The goal is to provide an interactive personal training experience: users get immediate feedback on performance, personalized scoring (e.g. based on standards like the USMC Physical Fitness Test), and progress tracking over time. The platform includes a web client and a Go-based backend API, with data synchronized securely across devices via user accounts (so your workouts and scores are available on web or mobile). PT Champion is designed for fitness enthusiasts and professionals alike, especially those who want objective metrics on exercise form and performance.
</project_overview>

<features>
* AI-Powered Exercise Tracking: Uses your device's camera for real-time rep counting and form analysis during bodyweight exercises (e.g. push-ups, sit-ups). A WebAssembly module encapsulates the grading logic to evaluate each repetition's quality (valid rep or not) and provide form feedback (e.g. depth of push-up, posture alignment). This computer-vision based tracker gives instant feedback on whether a rep was counted and how well it was performed (form score and tips).

* Personalized Scoring System: Assigns scores or grades to your workouts. For example, PT Champion can score a set of push-ups or a timed run according to official standards (such as US Marine Corps PFT scoring). The app computes points for reps or duration, enabling you to see how your performance measures up (e.g. a push-up score out of 70, run score out of 100). Form quality can also factor into your score – the app's grading algorithm provides a form score and rep count for each set.

* Workout Logging & History: Track various exercises – from strength moves (push-ups, pull-ups, sit-ups) to cardio (running) – with key metrics. The app records your repetitions, durations, and computed scores for each workout session. All workout data is saved to your profile, so you can review past sessions, see improvement over time, and identify trends. Data is presented with visuals (charts or summaries) to help you analyze your progress.

* GPS Run Tracking: For running or distance-based cardio, PT Champion utilizes location data (with permission) to record your route, distance, and pace. It can map your runs and calculate performance metrics like average pace and total distance. This feature is optional and uses your device GPS only when you start a run, ensuring no background tracking when not in use.

* Leaderboards and Competitive Challenges: PT Champion includes leaderboards so you can see how you rank against others. There are global leaderboards and optional local leaderboards based on location. For example, you might see how your best push-up score compares worldwide or just within your region. The app only uses coarse location (city/region) for rankings and never shares your exact location. Compete in challenges or simply use the rankings as motivation to improve.

* Cross-Device Sync: Your account data (profile and workouts) syncs to a secure cloud backend, so you can log in from multiple devices (iOS, Android, or Web) and access your updated workouts anywhere. You can start a workout on your phone and later analyze the results on the web dashboard. Offline logging is supported – if you record a workout offline, it will sync to the cloud once you reconnect.

* Notifications & Reminders: The app can send push notifications (or browser notifications on web) to remind you of workouts or provide updates. For example, you can enable daily workout reminders or get notified when you hit a new personal record. Notification permissions are optional and customizable.

* Device Integration (Planned): PT Champion is built with extensibility in mind. It can integrate with external fitness devices like heart-rate monitors or smartwatches. For instance, you can connect a Bluetooth HR monitor to include heart rate data in your workout logs. (Device management UI is already present, and support for wearables is on the roadmap.) These sensors further enrich the feedback – e.g. showing your heart rate trends during a workout.

* Security & Privacy: All data is transmitted securely (HTTPS) and stored in an encrypted database. Users create accounts with email/username and password; authentication uses JWT tokens for secure API calls. The app emphasizes privacy – camera visuals are processed on-device (no video is uploaded), and personal data is not shared with third parties. (See the Privacy Policy for details.)
</features>

<tech_stack>
Frontend (Web): The web client is a React application written in TypeScript. It uses the Vite build tool for fast development and bundling, and leverages Radix UI and Tailwind CSS for a modern, responsive UI theme. State management is handled primarily through React hooks and context, supplemented by React Query (TanStack Query) for data fetching and caching of API calls. For visuals and charts, libraries like Recharts and React-Leaflet (for maps) are included. The app's core differentiator is its use of TensorFlow.js PoseNet for pose estimation – on the web, the user's browser runs a lightweight pose detection model to get keypoints from the camera feed. These keypoints are then passed into a WebAssembly module (compiled from Go) for consistent exercise grading logic across platforms. The WASM module, built with TinyGo, encapsulates algorithms to count reps and score form, ensuring that the web client can provide realtime feedback efficiently in the browser. End-to-end tests are written with Cypress (there's a cypress/ suite for tests like push-up rep detection) to ensure reliability of the tracking features.

Backend (Server): The backend is a RESTful API server built with Go. It uses the high-performance Echo framework for routing and middleware. The server exposes endpoints for user authentication, workout logging, retrieving stats/leaderboards, etc., typically under an /api/v1/* namespace. Data is persisted in a PostgreSQL database (with schema migrations managed via tools like golang-migrate). The app's data models (users, exercises, workout entries, leaderboards) are defined in the database, and the Go code uses a mix of SQL (possibly via an ORM or query builder) to interact with it. For caching and fast lookups, the backend also integrates Redis – for example, to store session refresh tokens and to cache expensive leaderboard calculations. Authentication is implemented with JWT tokens (access and refresh tokens); the server issues JWTs on login and expects a valid token on protected endpoints. Refresh tokens are stored securely (in Redis or in-memory store) to allow token renewal. The backend is built for cloud deployment and scalability: it includes support for OpenTelemetry instrumentation (e.g. exporting traces to Jaeger) and structured logging for observability. The codebase shows configuration for cloud environments (e.g. Azure Key Vault integration for secrets and Flagsmith for feature flags in config). The server is containerized via Docker; a Docker Compose setup is provided to run the API along with its PostgreSQL, Redis, and Jaeger services for local development. In production, the API is designed to be deployed as a container (e.g. to Azure Web App or similar), and the static frontend can be served separately (or via a CDN).

Mobile: (Beyond the scope of this repository's web/backend focus) PT Champion also offers native iOS and Android clients. They are built with Swift (iOS) and Kotlin (Android) respectively, using device-native APIs for camera and sensors. These apps communicate with the same Go backend API. The core exercise grading logic is shared across platforms – for instance, the iOS app implements the same scoring system (USMC PFT standards, etc.) in Swift. This shared approach ensures consistency: whether you use the web app or mobile app, a given performance yields the same score and feedback.
</tech_stack>

<getting_started>
Follow these steps to set up a local development environment for PT Champion. You can run the system using Docker (recommended for an easy start) or run the frontend and backend locally with the required dependencies.

Prerequisites: You should have Docker and Docker Compose installed (if using the Docker setup), or alternatively Node.js (for the web client) and Go 1.20+ (for the server) installed on your machine. You'll also need a running PostgreSQL instance (if not using Docker) and Redis if you want full functionality.

Running with Docker Compose
1. Clone the repository: git clone https://github.com/toole-brendan/ptchampion.git  
2. cd ptchampion
3. Set up environment variables: Create a file named .env.dev in the project root (there is likely an example provided). At minimum, specify your database and secret keys. For example: # .env.dev
   DB_USER=user  
   DB_PASSWORD=password  
   DB_NAME=ptchampion  
   JWT_SECRET=<some random secret>  
   The Docker Compose configuration will use these values. The defaults in the compose file will set up a Postgres database with the same credentials (user/password@ptchampion), and it will disable SSL for local DB and use the service names for host resolution. You can adjust ports or other settings in docker-compose.yml if needed.
4. Launch the backend and services: Run the compose setup with: docker-compose up --build
   This will start the PostgreSQL database, Redis, a Jaeger tracing service (for OpenTelemetry), and the PT Champion Go API server. The first time, Docker will build the server image. Once up, the Go backend will be running on port 8080 (inside the container). The compose config also exposes port 8080 on your host machine. The API should become accessible at http://localhost:8080. The server container's entrypoint will automatically run any pending database migrations before starting the API, ensuring the schema is up-to-date.
5. Run the web client: The Docker setup does not containerize the web UI (for easy hot-reload during development). To start the React app, open a new terminal on your host machine and run: npm install   # install frontend dependencies
   npm run dev   # start Vite dev server
   (Note: If the frontend code and package.json are in the web/ subdirectory, you might need to cd web before running these commands. In this repo, however, the npm scripts are available at the root.)* This will launch the development server on port 3000 by default. The app will automatically proxy API requests to the backend (the dev server is configured to forward /api calls to localhost:8080). You should see log output confirming the web server running and maybe an opening of http://localhost:3000 in your browser.
6. Access the app: Open your browser to http://localhost:3000. You should see the PT Champion web application. You can register a new account (if email is required, any email format should work in dev) and start using the app. With the backend running, workouts you log will be saved to the database. Try enabling your camera on the "Workout" or "Practice" screen to use the computer vision rep counting feature – you'll see the app analyze the video and count your reps in real time. The default dev environment might have a test mode or use dummy data (there are dev shortcuts in the code to simulate tokens and data), but you can also use the real functionality if your environment variables (e.g. JWT secret) are set up.
7. Run tests (optional): PT Champion includes both backend tests and end-to-end tests. You can run make backend-test to execute Go tests for the server logic, and npm run test (or npm run cy:open if configured) for frontend tests. Ensure the services are running (especially for any integration tests that hit the DB).

Running backend and frontend manually (without Docker)
If you prefer not to use Docker, you can run each component directly:
* Database: Install PostgreSQL locally and create a database (name "ptchampion" by default). Update environment variables (DB_HOST, DB_USER, DB_PASSWORD, etc.) in a .env or .env.dev file or directly in your shell. Also run a Redis server locally if you want refresh token support (or set REDIS_URL to empty to use an in-memory store for dev). Apply database migrations by running: make migrate (which uses the migrate tool) or using the provided script (./scripts/migrate.sh up).
* Backend: Install Go, then compile and run the server: go run cmd/server/main.go
  Ensure your environment variables are loaded so the server can connect to the DB and know the JWT secret. By default, the server listens on port 8080 (configurable via the PORT env var). You should see log output indicating it connected to the database and started the server on :8080.
* Web client: Install Node.js (v18+). Navigate to the web/ directory (if applicable) and run npm install. Then start the dev server: npm run dev. This should launch at localhost:3000. (If needed, update the proxy or CLIENT_ORIGIN config for the backend so CORS allows the dev server's origin – by default it expects localhost:5173 or 3000 as configured.)

Once both backend and frontend are running, you can use the app at http://localhost:3000 (or the port shown in the console). The two should communicate seamlessly – for instance, registering a user on the frontend will call the backend API (POST /api/v1/users/register) and the data will appear in your Postgres DB. Use the Makefile targets for convenience (e.g. make dev may spin up Docker containers, etc.).
</getting_started>

<directory_structure>
The repository is organized into front-end and back-end codebases, plus mobile apps and configuration scripts. For clarity, here's an overview of the web and backend directories (and key subdirectories):

ptchampion/
├── web/                      # Frontend web application (React + TypeScript)
│   ├── public/               # Static assets (icons, privacy policy, etc.)
│   ├── src/                  # Application source code
│   │   ├── components/       # Reusable UI components (buttons, dialogs, etc.)
│   │   ├── pages/            # Page components for each route (Settings, Profile, etc.)
│   │   ├── lib/              # Utility modules (API client, hooks, context, config)
│   │   ├── services/         # Frontend services (e.g. wrapper calls to backend API)
│   │   └── types/            # TypeScript type definitions (app models, external libs)
│   ├── vite.config.ts        # Vite configuration for dev server and build
│   ├── tailwind.config.js    # Tailwind CSS configuration (theme and plugins)
│   └── package.json          # Frontend build scripts and dependencies (integrated at root)
│
├── backend/                  # (Logical grouping for server-side code – in repo, Go code is at root level)
│   ├── cmd/                  # Command-line entry points for different binaries
│   │   ├── server/           # Main API server application entry (main.go)
│   │   └── wasm/             # WebAssembly module for client-side grading (main.go)
│   ├── internal/             # Go internal packages for core functionality
│   │   ├── api/              # API route definitions and handler wiring
│   │   │   ├── routes.go     # Registers high-level routes (endpoints) on the Echo server
│   │   │   └── handlers/     # HTTP handler implementations for each API endpoint (business logic)
│   │   ├── auth/             # Authentication logic (password hashing, JWT token service)
│   │   ├── config/           # Configuration loading (env variables, .env files, Azure Key Vault)
│   │   ├── store/            # Data persistence layer 
│   │   │   ├── postgres/     # PostgreSQL database access (SQL queries, DB connection)
│   │   │   └── redis/        # Redis client and token store implementations
│   │   ├── logging/          # Logging setup (zerolog or similar, structured logging helpers)
│   │   └── telemetry/        # Telemetry (OpenTelemetry tracer setup, metrics)
│   ├── pkg/                  # Shared packages (usable by both server and WASM)
│   │   └── grading/          # Exercise grading logic (e.g. push-up rep validator, scoring algorithms)
│   ├── sql/                  # SQL database migration files (schema changes)
│   ├── scripts/              # Utility scripts (build, migrate, load-test, etc.)
│   └── Dockerfile            # Docker configuration to containerize the Go backend
│
└── (ios/ and android/ directories exist for the native mobile apps, omitted here)

In summary, the web folder contains the React app (with pages, components, and utilities for calling the backend API), while the backend Go code is organized under cmd, internal, and pkg (grouped as "backend" above). Notably, the backend's structure follows standard Go project layout: cmd/server for the main program, internal/* for application-specific packages (API handlers, auth, config, data stores), and pkg/grading which holds domain logic that is shared (also compiled to WebAssembly for use on the client side). This separation makes it easy to maintain a consistent scoring and validation logic between the server and client – for example, the push-up form evaluation lives in one place and is used by both the backend (to double-check submissions) and the frontend (to give instant feedback).
</directory_structure>

</pt_champion>