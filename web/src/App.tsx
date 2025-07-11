import { Suspense, lazy, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './lib/authContext';
import { FeatureFlagProvider } from './lib/featureFlags';
import { HeaderProvider } from './dashboard-message-context';
import { SettingsProvider } from './lib/SettingsContext';

import { PoseProvider } from './lib/contexts/PoseContext';
import ProtectedRoute from './components/auth/ProtectedRoute';
import OfflineBanner from './components/OfflineBanner';
import CameraPermissionDialog from './components/ui/CameraPermissionDialog';
import { ToastProvider } from './components/ui/toast-provider';
import { ErrorReporter } from './components/ErrorReporter';
import { Login, Register, RegisterDebug } from './pages/auth';
import OAuthCallback from './pages/auth/OAuthCallback';
import { logger } from './lib/logger';

// Lazy load pages for code-splitting
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Exercises = lazy(() => import('./pages/Exercises'));
// Replace the old History with the new WorkoutHistoryView
const WorkoutHistoryView = lazy(() => import('./pages/WorkoutHistoryView'));
// Fix for HistoryDetail not having a default export
const HistoryDetail = lazy(() => import('./pages/HistoryDetail').then(module => ({ default: module.HistoryDetail })));
const Leaderboard = lazy(() => import('./pages/Leaderboard'));
const Profile = lazy(() => import('./pages/Profile'));
const Settings = lazy(() => import('./pages/Settings'));

// Import exercise trackers from exercises directory as canonical source
const PushupTracker = lazy(() => import('./pages/exercises/PushupTracker'));
const PullupTracker = lazy(() => import('./pages/exercises/PullupTracker'));
const SitupTracker = lazy(() => import('./pages/exercises/SitupTracker'));
const RunningTracker = lazy(() => import('./pages/exercises/RunningTracker'));

// Import workout completion page
const WorkoutComplete = lazy(() => import('./pages/WorkoutComplete'));

// Import rubric pages
const PushUpsRubric = lazy(() => import('./pages/rubrics/PushUpsRubric'));
const SitUpsRubric = lazy(() => import('./pages/rubrics/SitUpsRubric'));
const PullUpsRubric = lazy(() => import('./pages/rubrics/PullUpsRubric'));
const TwoMileRunRubric = lazy(() => import('./pages/rubrics/TwoMileRunRubric'));

// Loading component for suspense
const Loading = () => (
  <div className="flex h-screen items-center justify-center bg-cream">
    <div className="text-xl text-brass-gold">Loading...</div>
  </div>
);

// Not found page
const NotFound = () => (
  <div className="flex h-screen flex-col items-center justify-center gap-4 bg-cream">
    <h1 className="font-bold text-3xl text-brass-gold">404 - Page Not Found</h1>
    <p className="text-tactical-gray">The page you're looking for does not exist.</p>
    <button 
      onClick={() => window.location.href = '/'}
      className="mt-4 rounded-lg bg-brass-gold px-4 py-2 text-white transition-colors hover:bg-brass-gold/90"
    >
      Return Home
    </button>
  </div>
);

// Define the type for App props
interface AppProps {
  queryClient?: QueryClient; // Optional for testing
}

/**
 * Main application component
 */
function App({ queryClient }: AppProps) {
  // Create a default QueryClient if none provided
  const qclient = queryClient || new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 1000 * 60 * 5, // 5 minutes
        retry: 2,
        // Request deduplication settings
        refetchOnWindowFocus: false, // Prevent refetch on window focus
        refetchOnReconnect: 'always', // Refetch on reconnect
        // Deduplicate requests - queries with the same key will share results
        // This prevents duplicate API calls when multiple components request the same data
        structuralSharing: true, // Share data structurally between queries (default)
      },
      mutations: {
        retry: 1, // Retry failed mutations once
      },
    },
  });

  // Removed eager pose detector initialization - will be initialized lazily by exercise components

  return (
    <QueryClientProvider client={qclient}>
      <AuthProvider>
        <SettingsProvider>
          <FeatureFlagProvider>
            <HeaderProvider>
              <PoseProvider>
                <ToastProvider>
                  {/* Add ErrorReporter to initialize error reporting */}
                  <ErrorReporter />
                  <Router>
                    <Suspense fallback={<Loading />}>
                      <Routes>
                        {/* Public routes */}
                        <Route path="/login" element={<Login />} />
                        <Route path="/register" element={<Register />} />
                        <Route path="/register-debug" element={<RegisterDebug />} />
                        <Route path="/auth/callback" element={<OAuthCallback />} />
                        
                        {/* Protected routes - require authentication */}
                        <Route path="/" element={<ProtectedRoute />}>
                          <Route index element={<Dashboard />} />
                          <Route path="dashboard" element={<Dashboard />} />
                          <Route path="exercises" element={<Exercises />} />
                          {/* Use the new WorkoutHistoryView component */}
                          <Route path="history" element={<WorkoutHistoryView />} />
                          <Route path="history/:id" element={<HistoryDetail />} />
                          <Route path="leaderboard" element={<Leaderboard />} />
                          <Route path="profile" element={<Profile />} />
                          <Route path="settings" element={<Settings />} />
                          
                          {/* Exercise tracking routes - canonical source of truth */}
                          <Route path="exercises/pushups" element={<PushupTracker />} />
                          <Route path="exercises/pullups" element={<PullupTracker />} />
                          <Route path="exercises/situps" element={<SitupTracker />} />
                          <Route path="exercises/running" element={<RunningTracker />} />
                          
                          {/* Workout completion page */}
                          <Route path="complete" element={<WorkoutComplete />} />

                          {/* Rubric pages */}
                          <Route path="rubrics/pushups" element={<PushUpsRubric />} />
                          <Route path="rubrics/situps" element={<SitUpsRubric />} />
                          <Route path="rubrics/pullups" element={<PullUpsRubric />} />
                          <Route path="rubrics/running" element={<TwoMileRunRubric />} />

                          {/* Redirect from trackers paths to exercises paths */}
                          <Route path="trackers/*" element={<Navigate to="/exercises" replace />} />
                          <Route path="trackers/pushups" element={<Navigate to="/exercises/pushups" replace />} />
                          <Route path="trackers/pullups" element={<Navigate to="/exercises/pullups" replace />} />
                          <Route path="trackers/situps" element={<Navigate to="/exercises/situps" replace />} />
                          <Route path="trackers/running" element={<Navigate to="/exercises/running" replace />} />
                        </Route>
                        
                        {/* Catch-all route - redirect to NotFound */}
                        <Route path="*" element={<NotFound />} />
                      </Routes>
                    </Suspense>
                    {/* OfflineBanner moved outside of Routes but inside Router */}
                    <OfflineBanner />
                    {/* Camera permission dialog that will show when needed */}
                    <CameraPermissionDialog />
                  </Router>
                </ToastProvider>
              </PoseProvider>
            </HeaderProvider>
          </FeatureFlagProvider>
        </SettingsProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
