import React, { useEffect, useState } from 'react';
import { Outlet } from 'react-router-dom';
import MobileLayout from './MobileLayout';
import DesktopLayout from './DesktopLayout';

const Layout: React.FC = () => {
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);

  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768);
    };

    window.addEventListener('resize', handleResize);
    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, []);

  // Use the appropriate layout based on screen size
  return isMobile ? (
    <MobileLayout>
      <Outlet />
    </MobileLayout>
  ) : (
    <DesktopLayout>
      <Outlet />
    </DesktopLayout>
  );
};

export default Layout; 