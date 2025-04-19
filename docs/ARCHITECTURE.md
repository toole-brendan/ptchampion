# PT Champion Architecture

This document provides an overview of the PT Champion system architecture using the C4 model (Context, Containers, Components, Code).

## 1. System Context Diagram

```mermaid
graph TD
    User["User (Service Member/Fitness Enthusiast)"]
    PTSystem["PT Champion System"]
    
    ExternalHRM["External Heart Rate Monitor"]
    GPSWatch["GPS Fitness Watch"]
    Cloud["Cloud Services"]
    
    User -->|Uses| PTSystem
    ExternalHRM -->|Sends Data| PTSystem
    GPSWatch -->|Sends Data| PTSystem
    PTSystem -->|Stores/Retrieves Data| Cloud
    
    classDef system fill:#1E241E,color:#BFA24D,stroke:#F4F1E6
    classDef external fill:#F4F1E6,color:#1E241E,stroke:#BFA24D
    classDef user fill:#C9CCA6,color:#1E241E,stroke:#4E5A48
    
    class PTSystem system
    class ExternalHRM,GPSWatch,Cloud external
    class User user
```

The PT Champion system serves users (service members and fitness enthusiasts) who need to track and improve their physical training exercises. The system integrates with external Bluetooth devices like heart rate monitors and GPS watches, and stores data in cloud services.

## 2. Container Diagram

```mermaid
graph TD
    User["User"]
    
    subgraph "PT Champion System"
        WebApp["Web Application\n(React PWA)"]
        iOSApp["iOS App\n(Swift/SwiftUI)"]
        AndroidApp["Android App\n(Kotlin/Compose)"]
        
        API["Backend API\n(Go/Echo)"]
        
        Database[(PostgreSQL Database)]
        Cache[(Redis Cache)]
    end
    
    User -->|Uses| WebApp
    User -->|Uses| iOSApp
    User -->|Uses| AndroidApp
    
    WebApp -->|API Calls| API
    iOSApp -->|API Calls| API
    AndroidApp -->|API Calls| API
    
    API -->|Reads/Writes| Database
    API -->|Caches Data| Cache
    
    classDef system fill:#1E241E,color:#BFA24D,stroke:#F4F1E6
    classDef db fill:#4E5A48,color:#F4F1E6,stroke:#BFA24D
    classDef app fill:#C9CCA6,color:#1E241E,stroke:#4E5A48
    classDef user fill:#FFFFFF,color:#1E241E,stroke:#4E5A48
    
    class User user
    class WebApp,iOSApp,AndroidApp app
    class API system
    class Database,Cache db
```

The PT Champion system consists of three main client applications (Web, iOS, and Android) that communicate with a central Go-based API. The API interacts with a PostgreSQL database for persistent storage and Redis for caching (particularly for leaderboard data).

## 3. Component Diagram: Backend API

```mermaid
graph TD
    APIGateway["API Gateway/Router"]
    
    subgraph "API Handlers"
        AuthHandler["Authentication Handler"]
        WorkoutHandler["Workout Handler"]
        LeaderboardHandler["Leaderboard Handler"]
        UserHandler["User Profile Handler"]
        GradingHandler["Exercise Grading Handler"]
    end
    
    subgraph "Core Services"
        AuthService["Auth Service\n(JWT, Token Management)"]
        WorkoutService["Workout Service\n(Recording, History)"]
        GradingService["Grading Service\n(Exercise Evaluation)"]
        LeaderboardService["Leaderboard Service\n(Rankings, Comparisons)"]
    end
    
    subgraph "Data Layer"
        Store["Store Interface"]
        PostgresStore["PostgreSQL Implementation"]
        RedisCache["Redis Cache Implementation"]
    end
    
    APIGateway -->|Routes Requests| AuthHandler
    APIGateway -->|Routes Requests| WorkoutHandler
    APIGateway -->|Routes Requests| LeaderboardHandler
    APIGateway -->|Routes Requests| UserHandler
    APIGateway -->|Routes Requests| GradingHandler
    
    AuthHandler --> AuthService
    WorkoutHandler --> WorkoutService
    LeaderboardHandler --> LeaderboardService
    UserHandler --> AuthService
    GradingHandler --> GradingService
    
    AuthService --> Store
    WorkoutService --> Store
    LeaderboardService --> Store
    LeaderboardService --> RedisCache
    
    Store --> PostgresStore
    
    classDef gateway fill:#1E241E,color:#BFA24D,stroke:#F4F1E6
    classDef handler fill:#C9CCA6,color:#1E241E,stroke:#4E5A48
    classDef service fill:#BFA24D,color:#1E241E,stroke:#F4F1E6
    classDef data fill:#4E5A48,color:#F4F1E6,stroke:#BFA24D
    
    class APIGateway gateway
    class AuthHandler,WorkoutHandler,LeaderboardHandler,UserHandler,GradingHandler handler
    class AuthService,WorkoutService,GradingService,LeaderboardService service
    class Store,PostgresStore,RedisCache data
```

The backend API is structured with clear separation of concerns:
- API Gateway/Router handles requests and routes them to the appropriate handlers
- Handlers process HTTP requests and delegate business logic to services
- Services contain core business logic
- Data layer abstracts database operations behind interfaces

## 4. Component Diagram: Web Application

```mermaid
graph TD
    Client["Web Client (Browser)"]
    
    subgraph "React Application"
        AppRouter["Router (React Router)"]
        
        subgraph "Pages"
            Dashboard["Dashboard"]
            Exercises["Exercises"]
            ExerciseTrackers["Exercise Trackers"]
            History["History"]
            Leaderboard["Leaderboard"]
            Profile["Profile"]
            Auth["Authentication Pages"]
        end
        
        subgraph "Shared Components"
            Layout["Layout Components"]
            UI["UI Components\n(shadcn/ui)"]
        end
        
        subgraph "Data & Services"
            APIClient["API Client"]
            AuthContext["Auth Context"]
            FeatureFlags["Feature Flags"]
            LocalStorage["IndexedDB Storage"]
            SyncService["Sync Service"]
            MediapipeService["MediaPipe\nPose Detection"]
            BluetoothService["Web Bluetooth\nHRM Service"]
        end
    end
    
    Client --> AppRouter
    
    AppRouter --> Dashboard
    AppRouter --> Exercises
    AppRouter --> ExerciseTrackers
    AppRouter --> History
    AppRouter --> Leaderboard
    AppRouter --> Profile
    AppRouter --> Auth
    
    Dashboard --> Layout
    Exercises --> Layout
    ExerciseTrackers --> Layout
    History --> Layout
    Leaderboard --> Layout
    Profile --> Layout
    
    Dashboard --> APIClient
    Exercises --> APIClient
    ExerciseTrackers --> APIClient
    History --> APIClient
    Leaderboard --> APIClient
    Profile --> APIClient
    Auth --> APIClient
    
    ExerciseTrackers --> MediapipeService
    ExerciseTrackers --> BluetoothService
    
    APIClient --> AuthContext
    APIClient --> SyncService
    SyncService --> LocalStorage
    
    classDef client fill:#FFFFFF,color:#1E241E,stroke:#4E5A48
    classDef router fill:#1E241E,color:#BFA24D,stroke:#F4F1E6
    classDef page fill:#C9CCA6,color:#1E241E,stroke:#4E5A48
    classDef component fill:#EDE9DB,color:#1E241E,stroke:#4E5A48
    classDef service fill:#BFA24D,color:#1E241E,stroke:#F4F1E6
    
    class Client client
    class AppRouter router
    class Dashboard,Exercises,ExerciseTrackers,History,Leaderboard,Profile,Auth page
    class Layout,UI component
    class APIClient,AuthContext,FeatureFlags,LocalStorage,SyncService,MediapipeService,BluetoothService service
```

The web application is built with React and follows a component-based architecture. It utilizes React Router for navigation, TanStack Query for data fetching, and various services for specific functionalities like pose detection and Bluetooth integration.

## 5. Component Diagram: Mobile Applications

Both iOS and Android applications follow similar architectural patterns with platform-specific implementations:

```mermaid
graph TD
    subgraph "Mobile Application (iOS/Android)"
        AppEntryPoint["App Entry Point"]
        
        subgraph "UI Layer"
            Views["Views/Screens"]
            ViewModels["ViewModels/Presenters"]
            UIComponents["UI Components"]
        end
        
        subgraph "Business Logic"
            Services["Services"]
            GradingLogic["Exercise Grading Logic"]
            PoseDetection["Pose Detection"]
            BluetoothManager["Bluetooth Manager"]
            LocationManager["Location Manager"]
        end
        
        subgraph "Data Layer"
            APIService["API Service"]
            LocalStorage["Local Storage\n(SwiftData/DataStore)"]
            SyncManager["Sync Manager"]
        end
    end
    
    AppEntryPoint --> Views
    Views --> ViewModels
    Views --> UIComponents
    
    ViewModels --> Services
    ViewModels --> APIService
    
    Services --> GradingLogic
    Services --> PoseDetection
    Services --> BluetoothManager
    Services --> LocationManager
    
    Services --> LocalStorage
    Services --> SyncManager
    SyncManager --> APIService
    
    classDef entry fill:#1E241E,color:#BFA24D,stroke:#F4F1E6
    classDef ui fill:#C9CCA6,color:#1E241E,stroke:#4E5A48
    classDef logic fill:#BFA24D,color:#1E241E,stroke:#F4F1E6
    classDef data fill:#4E5A48,color:#F4F1E6,stroke:#BFA24D
    
    class AppEntryPoint entry
    class Views,ViewModels,UIComponents ui
    class Services,GradingLogic,PoseDetection,BluetoothManager,LocationManager logic
    class APIService,LocalStorage,SyncManager data
```

The mobile applications use MVVM architecture with platform-specific implementations:
- iOS: SwiftUI for UI, Combine/Swift Concurrency for async operations, SwiftData for local storage
- Android: Jetpack Compose for UI, Coroutines for async operations, Room/DataStore for local storage

## 6. Data Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant ClientApp as Client App (Web/iOS/Android)
    participant API as Backend API
    participant DB as Database
    participant Cache as Redis Cache
    
    User->>ClientApp: Start Exercise Session
    
    alt Offline Mode
        ClientApp->>ClientApp: Store Exercise Data Locally
    else Online Mode
        ClientApp->>API: POST /api/v1/workouts
        API->>DB: Save Workout Data
        API->>ClientApp: Return Workout ID & Status
    end
    
    User->>ClientApp: Complete Exercise
    
    ClientApp->>ClientApp: Process Exercise Data
    
    alt Using Computer Vision
        ClientApp->>ClientApp: Run Pose Detection
        ClientApp->>ClientApp: Grade Exercise Form
    end
    
    alt Offline Mode
        ClientApp->>ClientApp: Store Results Locally
        ClientApp->>ClientApp: Queue for Sync
    else Online Mode
        ClientApp->>API: PUT /api/v1/workouts/{id}
        API->>DB: Update Workout Results
        API->>Cache: Update Leaderboard Cache
        API->>ClientApp: Return Success
    end
    
    User->>ClientApp: View Leaderboard
    
    ClientApp->>API: GET /api/v1/leaderboards
    API->>Cache: Get Leaderboard Data
    Cache->>API: Return Cached Data
    API->>ClientApp: Return Leaderboard Rankings
    
    ClientApp->>User: Display Results
```

This sequence diagram illustrates how data flows through the system during typical exercise tracking, showing both online and offline scenarios, and the synchronization process.

## 7. Deployment Architecture (Azure)

```mermaid
graph TD
    subgraph "Client Devices"
        WebBrowser["Web Browser"]
        iOSDevice["iOS Device"]
        AndroidDevice["Android Device"]
    end

    subgraph "Azure Cloud Infrastructure"
        subgraph "Networking & Delivery"
            FrontDoor["Azure Front Door\n(CDN, WAF, Routing)"]
        end

        subgraph "Compute Layer"
            AppService["App Service for Containers\n(Go Backend API)"]
        end

        subgraph "Data Layer"
            PostgreSQL["Azure Database for PostgreSQL"]
            RedisCache["Azure Cache for Redis"]
        end

        subgraph "Storage & Registry"
            StorageAccount["Azure Storage Account\n(Static Web Assets)"]
            ACR["Azure Container Registry"]
        end

        subgraph "Observability & Security"
            AppInsights["Application Insights"]
            Monitor["Azure Monitor"]
            KeyVault["Azure Key Vault"]
        end
    end

    WebBrowser -->|HTTPS| FrontDoor
    iOSDevice -->|HTTPS| FrontDoor
    AndroidDevice -->|HTTPS| FrontDoor

    FrontDoor -->|Route Web Requests| StorageAccount
    FrontDoor -->|Route API Requests| AppService

    AppService -->|Pulls Image| ACR
    AppService -->|Query Data| PostgreSQL
    AppService -->|Cache Data| RedisCache
    AppService -->|Secrets| KeyVault
    AppService -->|Logs & Metrics| AppInsights

    PostgreSQL -->|Logs & Metrics| Monitor
    RedisCache -->|Logs & Metrics| Monitor
    StorageAccount -->|Logs & Metrics| Monitor
    ACR -->|Logs & Metrics| Monitor
    AppInsights -->|Aggregates Data| Monitor

    classDef client fill:#FFFFFF,color:#1E241E,stroke:#4E5A48
    classDef network fill:#87CEEB,color:#1E241E,stroke:#4E5A48  // Light Sky Blue
    classDef compute fill:#1E241E,color:#BFA24D,stroke:#F4F1E6
    classDef data fill:#4E5A48,color:#F4F1E6,stroke:#BFA24D
    classDef storage fill:#C9CCA6,color:#1E241E,stroke:#4E5A48
    classDef observe fill:#BFA24D,color:#1E241E,stroke:#F4F1E6

    class WebBrowser,iOSDevice,AndroidDevice client
    class FrontDoor network
    class AppService compute
    class PostgreSQL,RedisCache data
    class StorageAccount,ACR storage
    class AppInsights,Monitor,KeyVault observe
```

The PT Champion system is deployed on Microsoft Azure using a suite of managed services:
- **Azure Front Door**: Provides global HTTP load balancing, CDN capabilities, WAF protection, and custom domain management. It routes traffic to the appropriate backend services.
- **Azure Storage Account**: Hosts the static files for the React web application (PWA), configured for static website hosting.
- **Azure App Service for Containers**: Runs the Go backend API as a containerized application, likely using the image stored in ACR.
- **Azure Container Registry (ACR)**: Stores and manages the Docker images for the backend API.
- **Azure Database for PostgreSQL - Flexible Server**: Provides a managed PostgreSQL database service.
- **Azure Cache for Redis**: Used for caching leaderboard data and potentially session management.
- **Azure Key Vault**: Securely stores application secrets like API keys and database credentials.
- **Azure Monitor & Application Insights**: Provide comprehensive monitoring, logging, tracing, and alerting for the application and infrastructure components.

## 8. Security Architecture

```mermaid
graph TD
    subgraph "Security Layers"
        NetSec["Network Security"]
        DataSec["Data Security"]
        AuthSec["Authentication Security"]
        AppSec["Application Security"]
    end
    
    subgraph "Network Security"
        TLS["TLS 1.2+"]
        WAF["Web Application Firewall"]
        CORS["CORS Policy"]
        SecHeaders["Security Headers"]
    end
    
    subgraph "Data Security"
        EncRest["Encryption at Rest"]
        EncTransit["Encryption in Transit"]
        DataMin["Data Minimization"]
    end
    
    subgraph "Authentication Security"
        JWT["JWT with Refresh"]
        SecStorage["Secure Token Storage"]
        PassHash["Password Hashing (Argon2)"]
    end
    
    subgraph "Application Security"
        InputVal["Input Validation"]
        CSRF["CSRF Protection"]
        DepScan["Dependency Scanning"]
        SAST["Static Analysis"]
    end
    
    NetSec -->|Implements| TLS
    NetSec -->|Implements| WAF
    NetSec -->|Implements| CORS
    NetSec -->|Implements| SecHeaders
    
    DataSec -->|Implements| EncRest
    DataSec -->|Implements| EncTransit
    DataSec -->|Implements| DataMin
    
    AuthSec -->|Implements| JWT
    AuthSec -->|Implements| SecStorage
    AuthSec -->|Implements| PassHash
    
    AppSec -->|Implements| InputVal
    AppSec -->|Implements| CSRF
    AppSec -->|Implements| DepScan
    AppSec -->|Implements| SAST
    
    classDef layer fill:#1E241E,color:#BFA24D,stroke:#F4F1E6
    classDef sec fill:#C9CCA6,color:#1E241E,stroke:#4E5A48
    
    class NetSec,DataSec,AuthSec,AppSec layer
    class TLS,WAF,CORS,SecHeaders,EncRest,EncTransit,DataMin,JWT,SecStorage,PassHash,InputVal,CSRF,DepScan,SAST sec
```

The PT Champion system implements a layered security approach covering network, data, authentication, and application layers with specific security controls in each layer.

## Technology Stack Summary

### Backend
- **Language**: Go 1.22
- **Web Framework**: Echo
- **ORM**: sqlc (SQL code generation)
- **Database**: PostgreSQL
- **Caching**: Redis
- **API Design**: OpenAPI 3.0
- **Authentication**: JWT with refresh tokens

### Web Frontend
- **Language**: TypeScript
- **Framework**: React
- **Build Tool**: Vite
- **Styling**: Tailwind CSS + shadcn/ui
- **State Management**: TanStack Query (React Query)
- **Offline Storage**: IndexedDB
- **PWA Features**: Service Workers, Background Sync
- **Computer Vision**: MediaPipe Tasks Vision
- **Bluetooth**: Web Bluetooth API

### iOS
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Local Storage**: SwiftData
- **Vision Processing**: Apple Vision framework
- **Bluetooth**: CoreBluetooth

### Android
- **Language**: Kotlin
- **UI Framework**: Jetpack Compose
- **Architecture**: MVVM + Clean Architecture
- **Local Storage**: DataStore
- **Vision Processing**: MediaPipe
- **Bluetooth**: Android Bluetooth LE API

### Infrastructure & DevOps
- **Cloud Provider**: Azure
- **IaC**: Terraform
- **Container Orchestration**: ECS Fargate
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch, X-Ray, Grafana
- **Security Scanning**: Snyk, grype/syft, pre-commit hooks 