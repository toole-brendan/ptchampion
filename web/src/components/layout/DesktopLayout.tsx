import React from 'react';
import { useLocation } from 'react-router-dom';
import { User, Sun, Moon } from 'lucide-react';
import { useAuth } from '../../lib/authContext';
import { useTheme } from '@/lib/themeContext';
import { useHeaderContext } from '@/dashboard-message-context';
import SyncIndicator from '@/components/SyncIndicator';
import Sidebar from './Sidebar';

const DesktopLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { logout } = useAuth();
  const { userName } = useHeaderContext();
  const { theme, toggleTheme } = useTheme();

  return (
    <div className="flex min-h-screen bg-background">
      {/* Sidebar */}
      <Sidebar 
        username={userName || 'User'} 
        onLogout={logout} 
      />
      
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
            {/* Theme toggle */}
            <button 
              onClick={toggleTheme} 
              className="flex size-10 items-center justify-center rounded-full bg-brass-gold/20 text-brass-gold hover:bg-brass-gold/30"
              aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
            >
              {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
            </button>
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