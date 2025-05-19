import React from 'react';
import { useAuth } from '../../lib/authContext';
import { useHeaderContext } from '@/dashboard-message-context';
import OfflineBanner from '@/components/OfflineBanner';
import TopNavBar from './TopNavBar';

const DesktopLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { logout } = useAuth();
  const { userName } = useHeaderContext();

  return (
    <div className="flex min-h-screen flex-col bg-cream">
      {/* Top navigation bar */}
      <TopNavBar username={userName || 'User'} onLogout={logout} />
      
      {/* Offline Banner positioned below header */}
      <div className="relative z-30">
        <OfflineBanner />
      </div>
      
      <main className="mx-auto w-full max-w-5xl flex-1 bg-cream p-section">
        {children}
      </main>
    </div>
  );
};

export default DesktopLayout; 