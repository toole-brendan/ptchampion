import React from 'react';
import { User } from 'lucide-react';
import { useAuth } from '../../lib/authContext';
import { useHeaderContext } from '@/dashboard-message-context';
import SyncIndicator from '@/components/SyncIndicator';
import OfflineBanner from '@/components/OfflineBanner';
import Sidebar from './Sidebar';

const DesktopLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { logout } = useAuth();
  const { userName } = useHeaderContext();

  return (
    <div className="flex min-h-screen bg-cream">
      {/* Sidebar */}
      <Sidebar 
        username={userName || 'User'} 
        onLogout={logout} 
      />
      
      {/* Main Content */}
      <div className="flex flex-1 flex-col">
        <header className="sticky top-0 z-40 flex h-16 items-center justify-between bg-deep-ops px-content text-cream shadow-medium">
          <div className="flex-1">
            <h1 className="flex items-center font-heading text-xl text-brass-gold">
              {userName ? `${userName}` : "PT Champion"}
              <SyncIndicator />
            </h1>
          </div>
          <div className="items-center gap-2 md:flex">
            {/* Profile Menu (Can be expanded later) */}
            <div className="focus:ring/50 flex size-10 cursor-pointer items-center justify-center rounded-full bg-brass-gold/20 text-brass-gold transition-colors hover:bg-brass-gold/30 focus:outline-none focus:ring-2 focus:ring-brass-gold">
              <User size={20} />
            </div>
          </div>
        </header>
        
        {/* Offline Banner positioned below header */}
        <div className="relative z-30">
          <OfflineBanner />
        </div>
        
        <main className="mx-auto w-full max-w-5xl flex-1 bg-cream p-section">
          {children}
        </main>
      </div>
    </div>
  );
};

export default DesktopLayout; 