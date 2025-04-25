import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell } from 'lucide-react';
import { useHeaderContext } from '@/dashboard-message-context';
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

  const navItems = [
    { to: '/', label: 'Home', icon: <Home size={20} /> },
    { to: '/exercises', label: 'Exercises', icon: <Dumbbell size={20} /> },
    { to: '/progress', label: 'Progress', icon: <BarChart2 size={20} /> },
    { to: '/leaderboard', label: 'Leaderboard', icon: <Award size={20} /> },
    { to: '/profile', label: 'Profile', icon: <User size={20} /> },
  ];

  return (
    <div className="flex min-h-screen flex-col bg-cream pb-[60px]">
      <header className="flex h-16 items-center justify-between bg-gradient-to-r from-deep-ops/5 to-brass-gold/10 p-4 border-b border-brass-gold/20 shadow-sm">
        <div className="flex flex-col">
          <h1 className="font-heading text-sm tracking-wide text-command-black">
            {userName || "Welcome"}
          </h1>
          <div className="h-px w-0 animate-[expand_300ms_ease-out_forwards] bg-brass-gold motion-reduce:w-16 motion-reduce:animate-none"></div>
        </div>
        <div className="flex items-center">
          <div className="flex size-8 items-center justify-center rounded-full bg-brass-gold/20 text-brass-gold">
            <User size={16} />
          </div>
        </div>
      </header>
      
      <main className="mx-auto w-full max-w-5xl flex-1 p-5">
        {children}
      </main>
      
      <nav className="bottom-nav z-10">
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