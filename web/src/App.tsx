import { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './lib/authContext';
import { FeatureFlagProvider } from './lib/featureFlags';
import Layout from './components/layout/Layout';
import ProtectedRoute from './components/auth/ProtectedRoute';

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

// Lazy load exercise trackers
const PushupTracker = lazy(() => import('./pages/exercises/PushupTracker'));
const PullupTracker = lazy(() => import('./pages/exercises/PullupTracker'));
const SitupTracker = lazy(() => import('./pages/exercises/SitupTracker'));
const RunningTracker = lazy(() => import('./pages/exercises/RunningTracker'));

// Create a QueryClient for React Query
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      gcTime: 10 * 60 * 1000, // 10 minutes (use gcTime instead of cacheTime)
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

// Loading component for suspense
const Loading = () => (
  <div className="flex h-screen items-center justify-center bg-cream">
    <div className="text-xl text-brass-gold">Loading...</div>
  </div>
);

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <FeatureFlagProvider>
          <Router>
            <Suspense fallback={<Loading />}>
              <Routes>
                {/* Auth routes */}
                <Route path="/login" element={<Login />} />
                <Route path="/register" element={<Register />} />
                
                {/* Protected routes - using nested route pattern */}
                <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
                  <Route index element={<Dashboard />} />
                  <Route path="dashboard" element={<Dashboard />} />
                  <Route path="exercises" element={<Exercises />} />
                  <Route path="history" element={<History />} />
                  <Route path="history/:id" element={<HistoryDetail />} />
                  <Route path="leaderboard" element={<Leaderboard />} />
                  <Route path="profile" element={<Profile />} />
                  
                  {/* Exercise tracking routes */}
                  <Route path="exercises/pushups" element={<PushupTracker />} />
                  <Route path="exercises/pullups" element={<PullupTracker />} />
                  <Route path="exercises/situps" element={<SitupTracker />} />
                  <Route path="exercises/running" element={<RunningTracker />} />
                </Route>
                
                {/* Catch-all route */}
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </Suspense>
          </Router>
        </FeatureFlagProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
