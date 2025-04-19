import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell, LogOut } from 'lucide-react';
import { useAuth } from '../../lib/authContext';

// Logo component (temporary, replace with actual logo)
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <div className={`${className} font-heading text-brass-gold`}>PT</div>
);

const DesktopLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const currentPath = location.pathname;
  const { logout } = useAuth();

  const navItems = [
    { to: '/', label: 'Dashboard', icon: <Home size={20} /> },
    { to: '/exercises', label: 'Exercises', icon: <Dumbbell size={20} /> },
    { to: '/progress', label: 'Progress', icon: <BarChart2 size={20} /> },
    { to: '/leaderboard', label: 'Leaderboard', icon: <Award size={20} /> },
    { to: '/profile', label: 'Profile', icon: <User size={20} /> },
  ];

  return (
    <div className="flex min-h-screen bg-cream">
      {/* Sidebar */}
      <aside className="hidden w-64 flex-col bg-deep-ops p-6 text-cream md:flex">
        <div className="mb-10 flex items-center">
          <LogoIcon className="size-8" />
          <span className="ml-3 font-heading text-xl text-cream">PT CHAMPION</span>
        </div>
        
        <nav className="flex-1">
          <ul className="space-y-2">
            {navItems.map((item) => (
              <li key={item.to}>
                <Link
                  to={item.to}
                  className={`flex items-center gap-3 rounded-lg px-4 py-3 transition-colors ${
                    currentPath === item.to 
                      ? 'bg-brass-gold/10 text-brass-gold' 
                      : 'text-cream/70 hover:bg-brass-gold/5 hover:text-brass-gold'
                  }`}
                >
                  {item.icon}
                  <span className="font-sans font-medium">{item.label}</span>
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        
        <button 
          onClick={logout}
          className="mt-auto flex items-center gap-3 px-4 py-3 text-cream/70 hover:text-brass-gold"
        >
          <LogOut size={20} />
          <span>Logout</span>
        </button>
      </aside>
      
      {/* Main Content */}
      <div className="flex flex-1 flex-col">
        <header className="flex h-16 items-center bg-cream px-6 shadow-sm md:border-b md:border-army-tan/20">
          <div className="flex-1"></div>
          <div className="md:block">
            {/* Profile Menu (Can be expanded later) */}
            <div className="flex size-8 items-center justify-center rounded-full bg-brass-gold/20 text-brass-gold">
              <User size={18} />
            </div>
          </div>
        </header>
        
        <main className="mx-auto w-full max-w-7xl flex-1 p-6">
          {children}
        </main>
      </div>
    </div>
  );
};

export default DesktopLayout; 