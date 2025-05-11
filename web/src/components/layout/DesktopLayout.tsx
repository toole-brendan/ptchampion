import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, BarChart2, Award, User, Dumbbell, LogOut, ChevronLeft, ChevronRight, Sun, Moon } from 'lucide-react';
import { useAuth } from '../../lib/authContext';
import { useTheme } from '@/lib/themeContext';
import { cn } from "@/lib/utils";
import { useHeaderContext } from '@/dashboard-message-context';
import SyncIndicator from '@/components/SyncIndicator';

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
  const { userName } = useHeaderContext();
  const { theme, toggleTheme } = useTheme();

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
    <div className="flex min-h-screen bg-background">
      {/* Sidebar */}
      <aside className={cn(
        "flex flex-col bg-deep-ops p-6 text-cream shadow-large transition-all duration-300",
        isCollapsed ? "w-20" : "w-64",
        "hidden md:flex"
      )}>
        {/* Logo section - centered */}
        <div className="flex justify-center items-center mb-10">
          <div className="text-brass-gold text-2xl font-bold">PT CHAMPION</div>
        </div>
        
        <nav className="flex-1">
          <ul className="space-y-2">
            {navItems.map((item) => (
              <li key={item.to}>
                <Link
                  to={item.to}
                  className={`flex items-center ${
                    isCollapsed ? 'justify-center px-2 py-3' : 'px-4 py-3 gap-3'
                  } rounded-button transition-all ${
                    currentPath === item.to 
                      ? 'bg-brass-gold/20 text-brass-gold' 
                      : 'text-cream hover:bg-deep-ops/70 hover:text-brass-gold'
                  }`}
                  title={isCollapsed ? item.label : undefined}
                >
                  {/* Always show the icon, regardless of collapsed state */}
                  <div className="flex-shrink-0 mr-3">
                    {item.icon}
                  </div>
                  {!isCollapsed && <span className="font-semibold">{item.label}</span>}
                </Link>
              </li>
            ))}
          </ul>
        </nav>

        {/* Theme toggle button */}
        {!isCollapsed && (
          <button 
            onClick={toggleTheme}
            className="flex w-full items-center justify-between rounded-button py-2.5 px-4 text-cream/70 hover:bg-brass-gold/10 hover:text-brass-gold border border-cream/10 mb-3"
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            <span className="font-sans text-sm">{theme === 'dark' ? 'Light Mode' : 'Dark Mode'}</span>
            <div className="flex-shrink-0">
              {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
            </div>
          </button>
        )}
        
        <div className="mt-auto space-y-3">
          {/* Toggle button moved here */}
          <button 
            onClick={toggleSidebar}
            className="flex w-full items-center justify-center rounded-button py-2.5 text-cream/70 hover:bg-brass-gold/5 hover:text-brass-gold border border-cream/10"
            aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            <div className="flex-shrink-0">
              {isCollapsed ? <ChevronRight size={20} /> : <ChevronLeft size={20} />}
            </div>
            {!isCollapsed && <span className="ml-2 font-sans text-sm">Collapse</span>}
          </button>
          
          <button 
            onClick={logout}
            className={`flex items-center ${
              isCollapsed ? 'justify-center px-2 py-3' : 'px-4 py-3 gap-3'
            } rounded-button w-full text-cream/70 hover:bg-red-800/50 hover:text-red-300`}
            title={isCollapsed ? "Logout" : undefined}
          >
            <div className="flex-shrink-0">
              <LogOut size={20} />
            </div>
            {!isCollapsed && <span>Logout</span>}
          </button>
        </div>
      </aside>
      
      {/* Main Content */}
      <div className="flex flex-1 flex-col">
        <header className="flex h-16 items-center justify-between bg-deep-ops text-cream px-content shadow-medium">
          <div className="flex-1">
            <h1 className="font-heading text-brass-gold text-xl font-bold flex items-center">
              {userName ? `Hello, ${userName}` : "PT Champion"}
              <SyncIndicator />
            </h1>
          </div>
          <div className="md:flex items-center gap-2">
            {/* Collapsed view theme toggle */}
            {isCollapsed && (
              <button 
                onClick={toggleTheme} 
                className="flex size-10 items-center justify-center rounded-full bg-brass-gold/20 text-brass-gold hover:bg-brass-gold/30"
                aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
              >
                {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
              </button>
            )}
            {/* Profile Menu (Can be expanded later) */}
            <div className="flex size-10 items-center justify-center rounded-full bg-brass-gold/20 text-brass-gold hover:bg-brass-gold/30 cursor-pointer transition-colors focus:outline-none focus:ring-2 focus:ring-brass-gold focus:ring-opacity-50">
              <User size={20} />
            </div>
          </div>
        </header>
        
        <main className="mx-auto w-full max-w-7xl flex-1 p-section">
          {children}
        </main>
      </div>
    </div>
  );
};

export default DesktopLayout; 