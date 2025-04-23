import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell, LogOut, ChevronLeft, ChevronRight } from 'lucide-react';
import { useAuth } from '../../lib/authContext';
import { cn } from "@/lib/utils";

// Import the PT Champion logo (corrected file name)
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

const DesktopLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();
  const currentPath = location.pathname;
  const { logout } = useAuth();
  const [isCollapsed, setIsCollapsed] = React.useState(false);

  const navItems = [
    { to: '/', label: 'Dashboard', icon: <Home size={20} /> },
    { to: '/exercises', label: 'Exercises', icon: <Dumbbell size={20} /> },
    { to: '/progress', label: 'Progress', icon: <BarChart2 size={20} /> },
    { to: '/leaderboard', label: 'Leaderboard', icon: <Award size={20} /> },
    { to: '/profile', label: 'Profile', icon: <User size={20} /> },
  ];

  const toggleSidebar = () => {
    setIsCollapsed(!isCollapsed);
  };

  return (
    <div className="flex min-h-screen bg-cream">
      {/* Sidebar */}
      <aside className={cn(
        "flex flex-col bg-deep-ops p-6 text-cream transition-all duration-300",
        isCollapsed ? "w-20" : "w-64",
        "hidden md:flex"
      )}>
        <div className="flex items-center justify-between mb-10">
          <div className={cn(
            "flex items-center",
            isCollapsed ? "justify-center w-full" : "justify-start"
          )}>
            <LogoIcon className={cn("h-14 w-auto", isCollapsed && "mx-auto")} />
          </div>
          
          <button 
            onClick={toggleSidebar}
            className="text-cream/70 hover:text-brass-gold p-1"
            aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            {isCollapsed ? <ChevronRight size={20} /> : <ChevronLeft size={20} />}
          </button>
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
                  } ${isCollapsed ? 'justify-center' : ''}`}
                  title={isCollapsed ? item.label : undefined}
                >
                  {item.icon}
                  {!isCollapsed && <span className="font-sans font-medium">{item.label}</span>}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        
        <button 
          onClick={logout}
          className={`mt-auto flex items-center gap-3 px-4 py-3 text-cream/70 hover:text-brass-gold ${isCollapsed ? 'justify-center' : ''}`}
          title={isCollapsed ? "Logout" : undefined}
        >
          <LogOut size={20} />
          {!isCollapsed && <span>Logout</span>}
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