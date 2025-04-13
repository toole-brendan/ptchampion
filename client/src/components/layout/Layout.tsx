import React, { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';
import { useAuth } from '../../lib/authContext';

const Layout: React.FC = () => {
  const { user, logout } = useAuth();
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);

  const handleToggleMobileSidebar = () => {
    setIsMobileSidebarOpen(!isMobileSidebarOpen);
  };

  const handleCloseMobileSidebar = () => {
    setIsMobileSidebarOpen(false);
  };
  
  return (
    <div className="flex h-screen overflow-hidden bg-background">
      {/* Sidebar (Handles both desktop and mobile versions internally now) */}
      <Sidebar 
        username={user?.username || 'User'} 
        onLogout={logout} 
        isMobileOpen={isMobileSidebarOpen}
        onMobileClose={handleCloseMobileSidebar}
      />
      
      {/* Main Content Wrapper */}
      <div className="flex flex-col flex-1 overflow-hidden">
        {/* Header (for mobile menu button) */}
        <Header onMenuClick={handleToggleMobileSidebar} />
        
        {/* Main Content Area */}
        {/* Added pt-14 for mobile to offset sticky header, remove padding on md+ */}
        <main className="flex-1 overflow-auto bg-gray-50 p-4 sm:p-6 lg:p-8 md:pt-0">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default Layout; 