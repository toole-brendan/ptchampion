import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import Layout from './components/layout/Layout'
import Dashboard from './pages/Dashboard'
import Exercises from './pages/Exercises'
import History from './pages/History'
import Leaderboard from './pages/Leaderboard'
import Profile from './pages/Profile'
import PushupTracker from './pages/exercises/PushupTracker'
import SitupTracker from './pages/exercises/SitupTracker'
import PullupTracker from './pages/exercises/PullupTracker'
import RunningTracker from './pages/exercises/RunningTracker'
import LoginPage from './pages/auth/Login'
import RegisterPage from './pages/auth/Register'
import RegisterDebug from './pages/auth/RegisterDebug'
import { AuthProvider, useAuth } from './lib/authContext'

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

// A protected route component that redirects to login if not authenticated
const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated, isLoading } = useAuth();
  
  if (isLoading) {
    return <div>Loading authentication...</div>;
  }
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  return <>{children}</>;
};

function AppRoutes() {
  const { isAuthenticated } = useAuth();
  
  return (
    <Routes>
      <Route path="/login" element={
        isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />
      } />
      <Route path="/register" element={
        isAuthenticated ? <Navigate to="/" replace /> : <RegisterPage />
      } />
      <Route path="/register-debug" element={<RegisterDebug />} />
      
      <Route path="/auth" element={<Navigate to="/login" replace />} />
      
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
        <Route path="leaderboard" element={<Leaderboard />} />
        <Route path="profile" element={<Profile />} />
      </Route>
      
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
