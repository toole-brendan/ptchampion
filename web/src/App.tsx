import { BrowserRouter as Router, Route, Routes, Navigate, Link } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import Layout from './components/layout/Layout'
import Dashboard from './pages/Dashboard'
import Exercises from './pages/Exercises'
import History from './pages/History'
import { HistoryDetail } from './pages/HistoryDetail'
import Leaderboard from './pages/Leaderboard'
import Profile from './pages/Profile'
import PushupTracker from './pages/exercises/PushupTracker'
import SitupTracker from './pages/exercises/SitupTracker'
import PullupTracker from './pages/exercises/PullupTracker'
import RunningTracker from './pages/exercises/RunningTracker'
import LoginPage from './pages/auth/Login'
import RegisterPage from './pages/auth/Register'
import ProtectedRoute from './components/auth/ProtectedRoute'
import { AuthProvider } from './lib/authContext'

// Import our trackers components
import { TrackersIndex } from './pages/trackers'
import { PushupTracker as NewPushupTracker } from './pages/trackers/PushupTracker';
import { PullupTracker as NewPullupTracker } from './pages/trackers/PullupTracker';
import { SitupTracker as NewSitupTracker } from './pages/trackers/SitupTracker';
import { RunningTracker as NewRunningTracker } from './pages/trackers/RunningTracker';

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      gcTime: 1000 * 60 * 30, // 30 minutes (use gcTime instead of cacheTime)
      retry: 1, // Retry failed requests once
      refetchOnWindowFocus: true, // Refetch on window focus
    },
  },
});

function AppRoutes() {
  return (
    <Routes>
      {/* Public routes */}
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />

      {/* Tracker routes */}
      <Route path="/trackers" element={<TrackersIndex />} />
      <Route path="/trackers/pushups" element={<NewPushupTracker />} />
      <Route path="/trackers/pullups" element={<NewPullupTracker />} />
      <Route path="/trackers/situps" element={<NewSitupTracker />} />
      <Route path="/trackers/running" element={<NewRunningTracker />} />
      
      {/* Protected routes */}
      <Route path="/" element={
        <ProtectedRoute>
          <Layout />
        </ProtectedRoute>
      }>
        <Route index element={<Dashboard />} />
        <Route path="exercises" element={<Exercises />} />
        <Route path="exercises/pushup" element={<PushupTracker />} />
        <Route path="exercises/situp" element={<SitupTracker />} />
        <Route path="exercises/pullup" element={<PullupTracker />} />
        <Route path="exercises/run" element={<RunningTracker />} />
        <Route path="history" element={<History />} />
        <Route path="history/:id" element={<HistoryDetail />} />
        <Route path="leaderboard" element={<Leaderboard />} />
        <Route path="profile" element={<Profile />} />
      </Route>
      
      {/* Fallback route */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <Router>
          <AppRoutes />
        </Router>
      </AuthProvider>
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}

export default App
