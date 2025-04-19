import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell } from 'lucide-react';

// Logo component (temporary, replace with actual logo)
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <div className={`${className} text-brass-gold font-heading`}>PT</div>
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
    <div className="flex flex-col min-h-screen bg-cream pb-[60px]">
      <header className="p-4 bg-cream shadow-sm flex items-center justify-between h-16">
        <div className="flex items-center">
          <LogoIcon className="h-8 w-8" />
          <span className="font-heading text-command-black text-xl ml-2">PT CHAMPION</span>
        </div>
      </header>
      
      <main className="flex-1 p-5 max-w-5xl mx-auto w-full">
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