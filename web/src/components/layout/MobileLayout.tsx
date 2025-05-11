import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell, Sun, Moon } from 'lucide-react';
import { useHeaderContext } from '@/dashboard-message-context';
import { useTheme } from '@/lib/themeContext';
import SyncIndicator from '@/components/SyncIndicator';
import ptChampionLogo from '@/assets/pt_champion_logo.png';

// Logo component using the actual logo image
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <img 
    src={ptChampionLogo} 
    alt="PT Champion" 
    className={`${className} object-contain filter-brass-gold`} 
    style={{ filter: 'brightness(0) saturate(100%) invert(67%) sepia(30%) saturate(659%) hue-rotate(18deg) brightness(89%) contrast(88%)' }}
  />
);

const MobileLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const currentPath = location.pathname;
  const { userName } = useHeaderContext();
  const { theme, toggleTheme } = useTheme();

  const navItems = [
    { to: '/', label: 'Home', icon: <Home size={22} /> },
    { to: '/exercises', label: 'Exercises', icon: <Dumbbell size={22} /> },
    { to: '/progress', label: 'Progress', icon: <BarChart2 size={22} /> },
    { to: '/leaderboard', label: 'Leaderboard', icon: <Award size={22} /> },
    { to: '/profile', label: 'Profile', icon: <User size={22} /> },
  ];

  return (
    <div className="flex min-h-screen flex-col bg-background pb-[60px]">
      <header className="flex h-16 items-center justify-between bg-deep-ops text-cream px-content shadow-medium">
        <div className="flex flex-col">
          <h1 className="font-heading text-brass-gold text-xl font-bold flex items-center">
            {userName ? `Hello, ${userName}` : "PT Champion"}
            <SyncIndicator />
          </h1>
        </div>
        <div className="flex items-center gap-2">
          <button 
            onClick={toggleTheme} 
            className="flex size-10 items-center justify-center rounded-full bg-brass-gold/20 text-brass-gold"
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
          </button>
          <div className="flex size-10 items-center justify-center rounded-full bg-brass-gold/20 text-brass-gold">
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
            className={`bottom-nav-item ${currentPath === item.to ? 'active' : ''}`}
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