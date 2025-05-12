import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell } from 'lucide-react';
import { useHeaderContext } from '@/dashboard-message-context';
import SyncIndicator from '@/components/SyncIndicator';
import OfflineBanner from '@/components/OfflineBanner';

const MobileLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const currentPath = location.pathname;
  const { userName } = useHeaderContext();

  const navItems = [
    { to: '/', label: 'Home', icon: <Home size={22} /> },
    { to: '/exercises', label: 'Exercises', icon: <Dumbbell size={22} /> },
    { to: '/history', label: 'History', icon: <BarChart2 size={22} /> },
    { to: '/leaderboard', label: 'Leaderboard', icon: <Award size={22} /> },
    { to: '/profile', label: 'Profile', icon: <User size={22} /> },
  ];

  // Helper function to determine if a nav item is active
  const isNavItemActive = (itemPath: string) => {
    if (itemPath === '/') {
      return currentPath === '/' || currentPath === '/dashboard';
    }
    return currentPath.startsWith(itemPath);
  };

  return (
    <div className="flex min-h-screen flex-col bg-cream pb-[60px]">
      <header className="sticky top-0 z-40 flex h-16 items-center justify-between bg-deep-ops px-content text-cream shadow-medium">
        <div className="flex flex-col">
          <h1 className="flex items-center font-heading text-xl text-brass-gold">
            {userName ? `${userName}` : "PT Champion"}
            <SyncIndicator />
          </h1>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex size-10 items-center justify-center rounded-full bg-brass-gold bg-opacity-20 text-brass-gold">
            <User size={20} />
          </div>
        </div>
      </header>
      
      {/* Offline Banner positioned below header */}
      <div className="relative z-30">
        <OfflineBanner />
      </div>
      
      <main className="mx-auto w-full flex-1 px-content py-md">
        {children}
      </main>
      
      <nav className="bottom-nav">
        {navItems.map((item) => (
          <Link
            key={item.to}
            to={item.to}
            className={`bottom-nav-item ${isNavItemActive(item.to) ? 'active' : ''}`}
          >
            {item.icon}
            <span className="bottom-nav-label">{item.label}</span>
          </Link>
        ))}
      </nav>
    </div>
  );
};

export default MobileLayout; 