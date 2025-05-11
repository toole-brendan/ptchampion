import { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './lib/authContext';
import { FeatureFlagProvider } from './lib/featureFlags';
import { HeaderProvider } from './dashboard-message-context';
import { ThemeProvider } from './lib/themeContext';
import Layout from './components/layout/Layout';
import ProtectedRoute from './components/auth/ProtectedRoute';
import OfflineBanner from './components/OfflineBanner';

// Lazy load pages for code-splitting
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Login = lazy(() => import('./pages/auth/Login'));
const Register = lazy(() => import('./pages/auth/Register'));
const Exercises = lazy(() => import('./pages/Exercises'));
const History = lazy(() => import('./pages/History'));
// Fix for HistoryDetail not having a default export
const HistoryDetail = lazy(() => import('./pages/HistoryDetail').then(module => ({ default: module.HistoryDetail })));
const Leaderboard = lazy(() => import('./pages/Leaderboard'));
const Profile = lazy(() => import('./pages/Profile'));

// Import the trackers index
const TrackerIndex = lazy(() => import('./pages/trackers/index'));

// Import exercise trackers from a single source - using the exercises directory as canonical
const PushupTracker = lazy(() => import('./pages/exercises/PushupTracker'));
const PullupTracker = lazy(() => import('./pages/exercises/PullupTracker'));
const SitupTracker = lazy(() => import('./pages/exercises/SitupTracker'));
const RunningTracker = lazy(() => import('./pages/exercises/RunningTracker'));

// Loading component for suspense
const Loading = () => (
  <div className="flex h-screen items-center justify-center bg-cream">
    <div className="text-xl text-brass-gold">Loading...</div>
  </div>
);

// Not found page
const NotFound = () => (
  <div className="flex h-screen flex-col items-center justify-center gap-4 bg-cream">
    <h1 className="text-3xl font-bold text-brass-gold">404 - Page Not Found</h1>
    <p className="text-tactical-gray">The page you're looking for does not exist.</p>
    <button 
      onClick={() => window.location.href = '/'}
      className="mt-4 rounded-lg bg-brass-gold px-4 py-2 text-white hover:bg-brass-gold/90 transition-colors"
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
      },
    },
  });

  return (
    <QueryClientProvider client={qclient}>
      <ThemeProvider>
        <AuthProvider>
          <FeatureFlagProvider>
            <HeaderProvider>
              <Router>
                <OfflineBanner />
                <Suspense fallback={<Loading />}>
                  <Routes>
                    {/* Public routes */}
                    <Route path="/login" element={<Login />} />
                    <Route path="/register" element={<Register />} />
                    
                    {/* Protected routes - require authentication */}
                    <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                      <Route index element={<Dashboard />} />
                      <Route path="dashboard" element={<Dashboard />} />
                      <Route path="exercises" element={<Exercises />} />
                      <Route path="history" element={<History />} />
                      <Route path="history/:id" element={<HistoryDetail />} />
                      <Route path="leaderboard" element={<Leaderboard />} />
                      <Route path="profile" element={<Profile />} />
                      
                      {/* Tracker routes - both paths point to the same components */}
                      <Route path="trackers" element={<TrackerIndex />} />
                      <Route path="trackers/pushups" element={<PushupTracker />} />
                      <Route path="trackers/pullups" element={<PullupTracker />} />
                      <Route path="trackers/situps" element={<SitupTracker />} />
                      <Route path="trackers/running" element={<RunningTracker />} />
                      
                      {/* Exercise tracking routes - use the same components */}
                      <Route path="exercises/pushups" element={<PushupTracker />} />
                      <Route path="exercises/pullups" element={<PullupTracker />} />
                      <Route path="exercises/situps" element={<SitupTracker />} />
                      <Route path="exercises/running" element={<RunningTracker />} />
                    </Route>
                    
                    {/* Catch-all route - redirect to NotFound */}
                    <Route path="*" element={<NotFound />} />
                  </Routes>
                </Suspense>
              </Router>
            </HeaderProvider>
          </FeatureFlagProvider>
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
