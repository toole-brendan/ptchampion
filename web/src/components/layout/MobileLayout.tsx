import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell } from 'lucide-react';
import { useHeaderContext } from '@/dashboard-message-context';
import { useAuth } from '@/lib/authContext';
import SyncIndicator from '@/components/SyncIndicator';
import OfflineBanner from '@/components/OfflineBanner';
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { LogOut, Settings } from 'lucide-react';

const MobileLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const currentPath = location.pathname;
  const { userName } = useHeaderContext();
  const { logout } = useAuth();

  const navItems = [
    { to: '/', label: 'Home', icon: <Home size={22} /> },
    { to: '/exercises', label: 'Exercises', icon: <Dumbbell size={22} /> },
    { to: '/history', label: 'History', icon: <BarChart2 size={22} /> },
    { to: '/leaderboard', label: 'Leaderboard', icon: <Award size={22} /> },
  ];

  // Helper function to determine if a nav item is active
  const isNavItemActive = (itemPath: string) => {
    if (itemPath === '/') {
      return currentPath === '/' || currentPath === '/dashboard';
    }
    return currentPath.startsWith(itemPath);
  };

  return (
    <div className="flex min-h-screen flex-col bg-cream">
      {/* Offline Banner positioned at the top */}
      <div className="relative z-30">
        <OfflineBanner />
      </div>
      
      <main className="mx-auto w-full flex-1 px-content py-md pb-[70px]">
        {children}
      </main>
      
      {/* User profile button at bottom right */}
      <div className="fixed bottom-[70px] right-4 z-50">
        <Popover>
          <PopoverTrigger asChild>
            <div className="flex size-12 items-center justify-center rounded-full bg-brass-gold text-deep-ops cursor-pointer shadow-lg">
              <User size={24} />
            </div>
          </PopoverTrigger>
          <PopoverContent className="w-56 bg-deep-ops border border-brass-gold border-opacity-20 p-0">
            <div className="text-cream">
              <div className="border-b border-cream border-opacity-10 p-3">
                <p className="text-sm font-medium text-brass-gold">{userName}</p>
              </div>
              
              <div className="p-1">
                {/* Profile link */}
                <Link
                  to="/profile"
                  className="flex w-full items-center rounded-md px-3 py-2 text-sm transition-colors duration-150 ease-in-out text-olive-mist opacity-80 hover:bg-brass-gold hover:bg-opacity-20 hover:text-brass-gold hover:opacity-90"
                >
                  <User className="mr-2 h-4 w-4" />
                  <span>Profile</span>
                </Link>
                
                {/* Settings link */}
                <Link
                  to="/settings"
                  className="flex w-full items-center rounded-md px-3 py-2 text-sm transition-colors duration-150 ease-in-out text-olive-mist opacity-80 hover:bg-brass-gold hover:bg-opacity-20 hover:text-brass-gold hover:opacity-90"
                >
                  <Settings className="mr-2 h-4 w-4" />
                  <span>Settings</span>
                </Link>
                
                {/* Sync indicator */}
                <div className="flex w-full items-center rounded-md px-3 py-2 text-sm">
                  <span className="mr-2">Sync status:</span>
                  <SyncIndicator />
                </div>
                
                {/* Logout button */}
                <button
                  onClick={logout}
                  className="flex w-full items-center rounded-md px-3 py-2 text-sm transition-colors duration-150 ease-in-out text-olive-mist opacity-80 hover:bg-red-800 hover:bg-opacity-50 hover:text-red-300"
                >
                  <LogOut className="mr-2 h-4 w-4" />
                  <span>Logout</span>
                </button>
              </div>
            </div>
          </PopoverContent>
        </Popover>
      </div>

      {/* Bottom navigation bar (moved from top) */}
      <nav className="bottom-nav">
        {navItems.map((item) => {
          const isActive = isNavItemActive(item.to);
          return (
            <Link
              key={item.to}
              to={item.to}
              className={`bottom-nav-item ${isActive ? 'active' : ''}`}
              style={isActive ? {
                backgroundColor: 'rgba(191, 162, 77, 0.9)',
                color: '#1E241E',
                borderRadius: '8px',
                padding: '4px 8px'
              } : {}}
            >
              <div style={isActive ? { color: '#1E241E' } : {}}>
                {item.icon}
              </div>
              <span 
                className="bottom-nav-label"
                style={isActive ? { color: '#1E241E' } : {}}
              >
                {item.label}
              </span>
            </Link>
          );
        })}
      </nav>
    </div>
  );
};

export default MobileLayout; 