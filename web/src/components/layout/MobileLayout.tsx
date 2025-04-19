import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell } from 'lucide-react';

// Logo component (temporary, replace with actual logo)
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <div className={`${className} font-heading text-brass-gold`}>PT</div>
);

const MobileLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const currentPath = location.pathname;

  const navItems = [
    { to: '/', label: 'Home', icon: <Home size={20} /> },
    { to: '/exercises', label: 'Exercises', icon: <Dumbbell size={20} /> },
    { to: '/progress', label: 'Progress', icon: <BarChart2 size={20} /> },
    { to: '/leaderboard', label: 'Leaderboard', icon: <Award size={20} /> },
    { to: '/profile', label: 'Profile', icon: <User size={20} /> },
  ];

  return (
    <div className="flex min-h-screen flex-col bg-cream pb-[60px]">
      <header className="flex h-16 items-center justify-between bg-cream p-4 shadow-sm">
        <div className="flex items-center">
          <LogoIcon className="size-8" />
          <span className="ml-2 font-heading text-xl text-command-black">PT CHAMPION</span>
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