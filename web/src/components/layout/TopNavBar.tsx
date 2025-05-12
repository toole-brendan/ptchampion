import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { LogOut, User, ChevronDown, Settings } from 'lucide-react';
import { NAV_ITEMS } from '../../constants/navigation';
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from '@/lib/utils';
import SyncIndicator from '@/components/SyncIndicator';
import ptChampionLogo from '@/assets/pt_champion_logo.png';

// Define a type for navigation items
type NavItem = {
  name: string;
  path: string;
  icon: React.ComponentType<{ className?: string; size?: number }>;
};

interface TopNavBarProps {
  username: string;
  onLogout: () => void;
}

// Logo component using the actual logo image
const LogoIcon: React.FC<{ className?: string }> = ({ className }) => (
  <img 
    src={ptChampionLogo} 
    alt="PT Champion" 
    className={`${className} object-contain`} 
    style={{ filter: 'brightness(0) saturate(100%) invert(67%) sepia(30%) saturate(659%) hue-rotate(18deg) brightness(89%) contrast(88%)' }}
  />
);

const TopNavBar: React.FC<TopNavBarProps> = ({ username, onLogout }) => {
  const location = useLocation();
  const userInitial = username ? username.charAt(0).toUpperCase() : '?';
  
  // Helper function to check if a nav item is active
  const isNavItemActive = (path: string) => {
    if (path === '/') {
      return location.pathname === '/' || location.pathname === '/dashboard';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <header className="sticky top-0 z-40 flex h-16 w-full items-center bg-deep-ops px-content text-cream shadow-medium">
      {/* Left - Logo only */}
      <div className="flex items-center">
        <LogoIcon className="size-10" />
        <SyncIndicator />
      </div>

      {/* Center - Nav Items (exclude Profile and Settings) */}
      <nav className="mx-auto hidden md:flex items-center gap-6">
        {NAV_ITEMS.filter(item => item.name !== 'Profile' && item.name !== 'Settings').map(item => {
          const isActive = isNavItemActive(item.path);
          return (
            <Link
              key={item.path}
              to={item.path}
              className={cn(
                "flex items-center h-11 rounded-md px-2 transition-colors duration-150 ease-in-out focus-visible:ring-[var(--ring-focus)] focus-visible:outline-none",
                isActive
                  ? 'text-brass-gold bg-brass-gold bg-opacity-20 font-medium'
                  : 'text-olive-mist opacity-80 hover:text-brass-gold hover:opacity-90'
              )}
            >
              <div className="mr-2 shrink-0 size-5">
                <item.icon className="size-5" />
              </div>
              <span className="font-sans text-sm">{item.name}</span>
            </Link>
          );
        })}
      </nav>

      {/* Right - User Menu */}
      <Popover>
        <PopoverTrigger asChild>
          <div className="flex items-center gap-2 cursor-pointer">
            <div className="flex items-center gap-1 rounded-full bg-brass-gold/20 text-brass-gold px-3 py-1.5 hover:bg-brass-gold/30 transition-colors">
              <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-brass-gold font-semibold text-sm text-deep-ops">
                {userInitial}
              </div>
              <span className="ml-2 hidden md:inline text-brass-gold text-sm">
                {username}
              </span>
              <ChevronDown size={16} className="ml-1 hidden md:inline" />
            </div>
          </div>
        </PopoverTrigger>
        <PopoverContent className="w-56 bg-deep-ops border border-brass-gold border-opacity-20 p-0">
          <div className="text-cream">
            <div className="border-b border-cream border-opacity-10 p-3">
              <p className="text-sm font-medium text-brass-gold">{username}</p>
            </div>
            
            <div className="p-1">
              {/* Profile link */}
              <Link
                to="/profile"
                className="flex w-full items-center rounded-md px-3 py-2 text-sm transition-colors duration-150 ease-in-out text-olive-mist opacity-80 hover:bg-brass-gold hover:bg-opacity-20 hover:text-brass-gold hover:opacity-90"
              >
                <User className="mr-2 h-4 w-4" />
                <span>Profile</span>
              </Link>
              
              {/* Settings link */}
              <Link
                to="/settings"
                className="flex w-full items-center rounded-md px-3 py-2 text-sm transition-colors duration-150 ease-in-out text-olive-mist opacity-80 hover:bg-brass-gold hover:bg-opacity-20 hover:text-brass-gold hover:opacity-90"
              >
                <Settings className="mr-2 h-4 w-4" />
                <span>Settings</span>
              </Link>
              
              {/* Logout button */}
              <button
                onClick={onLogout}
                className="flex w-full items-center rounded-md px-3 py-2 text-sm transition-colors duration-150 ease-in-out text-olive-mist opacity-80 hover:bg-red-800 hover:bg-opacity-50 hover:text-red-300"
              >
                <LogOut className="mr-2 h-4 w-4" />
                <span>Logout</span>
              </button>
            </div>
          </div>
        </PopoverContent>
      </Popover>
    </header>
  );
};

export default TopNavBar; 