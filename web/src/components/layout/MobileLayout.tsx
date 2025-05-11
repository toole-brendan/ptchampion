import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell, Sun, Moon } from 'lucide-react';
import { useHeaderContext } from '@/dashboard-message-context';
import { useTheme } from '@/lib/themeContext';
import SyncIndicator from '@/components/SyncIndicator';

const MobileLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const currentPath = location.pathname;
  const { userName } = useHeaderContext();
  const { theme, toggleTheme } = useTheme();

  const navItems = [
    { to: '/', label: 'Home', icon: <Home size={22} /> },
    { to: '/exercises', label: 'Exercises', icon: <Dumbbell size={22} /> },
    { to: '/history', label: 'History', icon: <BarChart2 size={22} /> },
    { to: '/leaderboard', label: 'Leaderboard', icon: <Award size={22} /> },
    { to: '/profile', label: 'Profile', icon: <User size={22} /> },
  ];

  return (
    <div className="flex min-h-screen flex-col bg-background pb-[60px]">
      <header className="flex h-16 items-center justify-between bg-deep-ops px-content text-cream shadow-medium">
        <div className="flex flex-col">
          <h1 className="flex items-center font-heading text-xl text-brass-gold">
            {userName ? `Hello, ${userName}` : "PT Champion"}
            <SyncIndicator />
          </h1>
        </div>
        <div className="flex items-center gap-2">
          <button 
            onClick={toggleTheme} 
            className="bg-brass-gold/20 flex size-10 items-center justify-center rounded-full text-brass-gold"
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
          </button>
          <div className="bg-brass-gold/20 flex size-10 items-center justify-center rounded-full text-brass-gold">
            <User size={20} />
          </div>
        </div>
      </header>
      
      <main className="mx-auto w-full flex-1 px-content py-md">
        {children}
      </main>
      
      <nav className="bottom-nav">
        {navItems.map((item) => (
          <Link
            key={item.to}
            to={item.to}
            className={`bottom-nav-item ${
              item.to === '/' 
                ? currentPath === item.to 
                : currentPath.startsWith(item.to) 
                  ? 'active' 
                  : ''
            }`}
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