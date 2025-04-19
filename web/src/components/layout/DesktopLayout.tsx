import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell, LogOut } from 'lucide-react';
import { useAuth } from '../../lib/authContext';

// Logo component (temporary, replace with actual logo)
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <div className={`${className} text-brass-gold font-heading`}>PT</div>
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
      <aside className="hidden md:flex flex-col w-64 bg-deep-ops text-cream p-6">
        <div className="flex items-center mb-10">
          <LogoIcon className="h-8 w-8" />
          <span className="font-heading text-cream text-xl ml-3">PT CHAMPION</span>
        </div>
        
        <nav className="flex-1">
          <ul className="space-y-2">
            {navItems.map((item) => (
              <li key={item.to}>
                <Link
                  to={item.to}
                  className={`flex items-center gap-3 py-3 px-4 rounded-lg transition-colors ${
                    currentPath === item.to 
                      ? 'bg-brass-gold/10 text-brass-gold' 
                      : 'text-cream/70 hover:text-brass-gold hover:bg-brass-gold/5'
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
          className="flex items-center gap-3 py-3 px-4 text-cream/70 hover:text-brass-gold mt-auto"
        >
          <LogOut size={20} />
          <span>Logout</span>
        </button>
      </aside>
      
      {/* Main Content */}
      <div className="flex-1 flex flex-col">
        <header className="h-16 bg-cream shadow-sm md:border-b md:border-army-tan/20 flex items-center px-6">
          <div className="flex-1"></div>
          <div className="md:block">
            {/* Profile Menu (Can be expanded later) */}
            <div className="w-8 h-8 rounded-full bg-brass-gold/20 flex items-center justify-center text-brass-gold">
              <User size={18} />
            </div>
          </div>
        </header>
        
        <main className="flex-1 p-6 max-w-7xl mx-auto w-full">
          {children}
        </main>
      </div>
    </div>
  );
};

export default DesktopLayout; 