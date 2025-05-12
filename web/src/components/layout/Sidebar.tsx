import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  Home as HomeIcon, 
  User as UserIcon,
  Trophy as TrophyIcon,
  ChevronLeft as ChevronLeftIcon,
  ChevronRight as ChevronRightIcon,
  LogOut as LogOutIcon,
  X as XIcon,
  Camera as CameraIcon
} from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import ptChampionLogo from '@/assets/pt_champion_logo.png';
import { useFeatureFlags } from '@/lib/featureFlags';

interface IconProps extends React.SVGProps<SVGSVGElement> {
  size?: number;
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

// Define custom icons
const DumbbellIcon: React.FC<IconProps> = (props) => (
  <svg 
    xmlns="http://www.w3.org/2000/svg" 
    viewBox="0 0 24 24" 
    fill="none" 
    stroke="currentColor" 
    strokeWidth="2" 
    strokeLinecap="round" 
    strokeLinejoin="round" 
    {...props}
  >
    <path d="M6 4v16" />
    <path d="M10 4v16" />
    <path d="M14 4v16" />
    <path d="M18 4v16" />
    <path d="M3 8h18" />
    <path d="M3 16h18" />
  </svg>
);

const HistoryIcon: React.FC<IconProps> = (props) => (
  <svg 
    xmlns="http://www.w3.org/2000/svg" 
    viewBox="0 0 24 24" 
    fill="none" 
    stroke="currentColor" 
    strokeWidth="2" 
    strokeLinecap="round" 
    strokeLinejoin="round" 
    {...props}
  >
    <path d="M3 3v18h18" />
    <path d="M12 12H3V3" />
    <path d="M16 16v-4h-4" />
  </svg>
);

export interface SidebarProps {
  username: string;
  onLogout: () => void;
  isMobileOpen?: boolean;
  onMobileClose?: () => void;
}

// Navigation items
const NavItem = ({ to, icon, label, isCollapsed }: { to: string; icon: React.ReactNode; label: string; isCollapsed?: boolean }) => {
  const location = useLocation();
  const isActive = to === '/' 
    ? location.pathname === '/' || location.pathname === '/dashboard'
    : location.pathname.startsWith(to);
  
  return (
    <li>
      <Tooltip>
        <TooltipTrigger asChild>
          <Link
            to={to}
            className={cn(
              "group flex h-11 items-center rounded-md transition-colors duration-150 ease-in-out focus-visible:ring-[var(--ring-focus)] focus-visible:outline-none",
              isCollapsed ? 'justify-center px-0' : 'px-3',
              isActive
                ? 'bg-brass-gold bg-opacity-20 text-brass-gold font-medium'
                : 'text-olive-mist opacity-80 hover:bg-olive-mist hover:bg-opacity-10 hover:text-brass-gold hover:opacity-90'
            )}
          >
            <div className={cn("flex-shrink-0", isCollapsed ? 'size-5' : 'mr-3 size-5')}>
              {icon}
            </div>
            {!isCollapsed && <span className="font-sans text-sm">{label}</span>}
          </Link>
        </TooltipTrigger>
        {isCollapsed && (
          <TooltipContent side="right">
            {label}
          </TooltipContent>
        )}
      </Tooltip>
    </li>
  );
};

const Sidebar: React.FC<SidebarProps> = ({ 
  username, 
  onLogout, 
  isMobileOpen = false,
  onMobileClose 
}) => {
  const location = useLocation();
  const [isCollapsed, setIsCollapsed] = useState(false);
  const { isEnabled } = useFeatureFlags();

  useEffect(() => {
    if (isMobileOpen && onMobileClose) {
      onMobileClose();
    }
  }, [location.pathname, isMobileOpen, onMobileClose]);

  const navItems = [
    { name: 'Dashboard', path: '/', icon: HomeIcon },
    { name: 'Exercises', path: '/exercises', icon: DumbbellIcon },
    { name: 'History', path: '/history', icon: HistoryIcon },
    { name: 'Leaderboard', path: '/leaderboard', icon: TrophyIcon },
    { name: 'Profile', path: '/profile', icon: UserIcon },
  ];

  const toggleSidebarCollapse = () => {
    setIsCollapsed(!isCollapsed);
  };

  const userInitial = username ? username.charAt(0).toUpperCase() : '?';

  const sidebarContent = (
    <aside 
      className={cn(
        "bg-deep-ops text-cream flex flex-col transition-all duration-300 ease-in-out",
        "h-screen overflow-y-auto flex-shrink-0",
        "md:sticky md:top-0",
        isMobileOpen 
          ? "fixed inset-y-0 left-0 z-40 translate-x-0" 
          : "md:translate-x-0 -translate-x-full",
        isCollapsed ? 'w-20' : 'w-64'
      )}
      aria-label="Sidebar"
    >
      {isMobileOpen && onMobileClose && (
        <div className="absolute right-2 top-2 md:hidden">
          <Button 
            variant="ghost" 
            size="icon" 
            className="hover:bg-olive-mist hover:bg-opacity-10 text-army-tan hover:text-brass-gold"
            onClick={onMobileClose}
          >
            <XIcon className="size-5" />
          </Button>
        </div>
      )}

      {/* Logo section - properly centered */}
      <div className="border-cream border-opacity-10 flex items-center justify-center border-b p-4 py-6">
        <LogoIcon className={isCollapsed ? "size-12" : "size-14"} />
      </div>
      
      {/* User profile section */}
      <div className={cn(
        "border-b border-cream border-opacity-10 transition-all duration-300",
        isCollapsed ? 'py-4 px-2' : 'py-4 px-4'
      )}>
        <Tooltip>
          <TooltipTrigger asChild>
            <div className={cn("flex items-center", isCollapsed ? 'justify-center' : '')}>
              <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-brass-gold font-semibold text-sm text-deep-ops">
                {userInitial}
              </div>
              {!isCollapsed && (
                <span className="ml-3 truncate text-sm font-medium text-cream">
                  {username}
                </span>
              )}
            </div>
          </TooltipTrigger>
          {isCollapsed && (
            <TooltipContent side="right">
              {username}
            </TooltipContent>
          )}
        </Tooltip>
      </div>
      
      {/* Navigation items */}
      <nav className="mt-4">
        <ul className={cn("space-y-1", isCollapsed ? 'px-2' : 'px-4')}>
          {navItems.map((item) => (
            <NavItem 
              key={item.path}
              to={item.path}
              icon={<item.icon className="size-5" />}
              label={item.name}
              isCollapsed={isCollapsed}
            />
          ))}
        </ul>
        
        {/* Experimental Features Section */}
        {isEnabled('experimental_features', false) && (
          <div className="mt-6">
            <h4 className={cn(
              "text-xs text-gray-400 uppercase mb-2",
              isCollapsed ? 'text-center' : 'px-4'
            )}>
              {!isCollapsed && 'Experimental'}
            </h4>
            <ul className={cn("space-y-1 mb-6", isCollapsed ? 'px-2' : 'px-4')}>
              <NavItem
                to="/example/calibration"
                icon={<CameraIcon className="size-5" />}
                label="MediaPipe Calibration"
                isCollapsed={isCollapsed}
              />
              <NavItem
                to="/example/pushup-analyzer"
                icon={<DumbbellIcon className="size-5" />}
                label="Push-up Analyzer"
                isCollapsed={isCollapsed}
              />
              <NavItem
                to="/example/situp-analyzer"
                icon={<DumbbellIcon className="size-5" />}
                label="Sit-up Analyzer"
                isCollapsed={isCollapsed}
              />
              <NavItem
                to="/example/pullup-analyzer"
                icon={<DumbbellIcon className="size-5" />}
                label="Pull-up Analyzer"
                isCollapsed={isCollapsed}
              />
            </ul>
          </div>
        )}
      </nav>
      
      {/* Bottom controls section */}
      <div className={cn(
        "border-t border-cream border-opacity-10 transition-all duration-300 space-y-3 pt-3 mt-auto",
        isCollapsed ? 'px-2 py-3' : 'px-4 py-3'
      )}>
        {/* Toggle button moved here */}
        <Tooltip>
          <TooltipTrigger asChild>
            <button 
              onClick={toggleSidebarCollapse}
              className={cn(
                "flex w-full items-center rounded-md py-2.5 text-olive-mist opacity-80 border border-cream border-opacity-10 transition-all",
                "focus-visible:ring-[var(--ring-focus)] focus-visible:outline-none",
                "hover:bg-brass-gold hover:bg-opacity-20 hover:text-cream hover:border-brass-gold hover:border-opacity-40",
                isCollapsed ? 'justify-center px-0' : 'px-3 justify-center'
              )}
              aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
            >
              {isCollapsed ? <ChevronRightIcon size={20} /> : <ChevronLeftIcon size={20} />}
              {!isCollapsed && <span className="ml-2 text-sm">Collapse</span>}
            </button>
          </TooltipTrigger>
          {isCollapsed && (
            <TooltipContent side="right">
              {isCollapsed ? "Expand" : "Collapse"}
            </TooltipContent>
          )}
        </Tooltip>
        
        {/* Logout button */}
        <Tooltip>
          <TooltipTrigger asChild>
            <button 
              onClick={onLogout}
              className={cn(
                "group flex h-11 w-full items-center rounded-md text-sm transition-colors duration-150 ease-in-out",
                "text-olive-mist opacity-80 hover:bg-red-800 hover:bg-opacity-50 hover:text-red-300",
                "focus-visible:ring-[var(--ring-focus)] focus-visible:outline-none",
                isCollapsed ? 'justify-center px-0' : 'px-3'
              )}
            >
              <LogOutIcon className={cn("flex-shrink-0", isCollapsed ? 'size-5' : 'mr-3 size-5')} />
              {!isCollapsed && <span>Logout</span>}
            </button>
          </TooltipTrigger>
          {isCollapsed && (
            <TooltipContent side="right">
              Logout
            </TooltipContent>
          )}
        </Tooltip>
      </div>
    </aside>
  );

  return (
    <TooltipProvider delayDuration={100}>
      <div className="hidden md:flex md:shrink-0">
        {sidebarContent} 
      </div>

      {isMobileOpen && (
        <>
          <div 
            className="fixed inset-0 z-30 bg-black/50 md:hidden"
            onClick={onMobileClose}
            aria-hidden="true"
          ></div>
          {sidebarContent}
        </>
      )}
    </TooltipProvider>
  );
};

export default Sidebar; 