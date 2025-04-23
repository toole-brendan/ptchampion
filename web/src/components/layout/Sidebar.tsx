import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  Home as HomeIcon, 
  User as UserIcon,
  Trophy as TrophyIcon,
  ChevronLeft as ChevronLeftIcon,
  ChevronRight as ChevronRightIcon,
  LogOut as LogOutIcon,
  X as XIcon
} from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface IconProps extends React.SVGProps<SVGSVGElement> {
  size?: number;
}

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

const Sidebar: React.FC<SidebarProps> = ({ 
  username, 
  onLogout, 
  isMobileOpen = false,
  onMobileClose 
}) => {
  const location = useLocation();
  const [isCollapsed, setIsCollapsed] = useState(false);
  
  useEffect(() => {
    if (isMobileOpen && onMobileClose) {
      onMobileClose();
    }
  }, [location.pathname, isMobileOpen, onMobileClose]);
  
  const isActive = (path: string) => location.pathname === path;
  
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
        "bg-deep-ops text-cream transition-all duration-300 ease-in-out flex flex-col",
        "h-screen",
        "fixed inset-y-0 left-0 z-40",
        "md:static md:z-auto md:inset-auto md:translate-x-0",
        isMobileOpen ? "translate-x-0" : "-translate-x-full",
        isCollapsed ? 'w-20 md:w-20' : 'w-64 md:w-64'
      )}
      aria-label="Sidebar"
    >
      {isMobileOpen && onMobileClose && (
        <div className="absolute right-2 top-2 md:hidden">
          <Button 
            variant="ghost" 
            size="icon" 
            className="text-army-tan hover:bg-olive-mist/10 hover:text-brass-gold"
            onClick={onMobileClose}
          >
            <XIcon className="size-5" />
          </Button>
        </div>
      )}

      <div className={cn(
        "flex items-center border-b border-cream/10 transition-all duration-300 h-16", 
        isCollapsed ? 'px-2 justify-center' : 'px-4 justify-between'
      )}>
        {!isCollapsed && <h2 className="text-xl font-bold text-brass-gold">PT Champion</h2>}
        <Tooltip>
          <TooltipTrigger asChild>
            <button 
              onClick={toggleSidebarCollapse}
              className="rounded-md p-2 text-army-tan hover:bg-olive-mist/10 hover:text-brass-gold focus:outline-none focus:ring-2 focus:ring-brass-gold/60 focus:ring-opacity-50"
              aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
            >
              {isCollapsed ? <ChevronRightIcon size={20} /> : <ChevronLeftIcon size={20} />}
            </button>
          </TooltipTrigger>
          <TooltipContent side="right">
            {isCollapsed ? "Expand" : "Collapse"}
          </TooltipContent>
        </Tooltip>
      </div>
      
      <div className={cn(
        "border-b border-cream/10 transition-all duration-300",
        isCollapsed ? 'py-4 px-2' : 'py-4 px-4'
      )}>
        <Tooltip>
          <TooltipTrigger asChild>
            <div className={cn("flex items-center", isCollapsed ? 'justify-center' : '')}>
              <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-brass-gold text-sm font-semibold text-deep-ops">
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
      
      <nav className="mt-4 grow overflow-y-auto">
        <ul className={cn("space-y-1", isCollapsed ? 'px-2' : 'px-4')}>
          {navItems.map((item) => (
            <li key={item.path}>
               <Tooltip>
                 <TooltipTrigger asChild>
                    <Link
                      to={item.path}
                      className={cn(
                        "group flex h-11 items-center rounded-md transition-colors duration-150 ease-in-out",
                        isCollapsed ? 'justify-center px-0' : 'px-3',
                        isActive(item.path)
                          ? 'bg-brass-gold/20 text-brass-gold font-medium'
                          : 'text-army-tan hover:bg-olive-mist/10 hover:text-brass-gold'
                      )}
                    >
                      <item.icon className={cn("flex-shrink-0", isCollapsed ? 'size-5' : 'mr-3 size-5')} /> 
                      {!isCollapsed && <span className="text-sm font-sans">{item.name}</span>}
                    </Link>
                 </TooltipTrigger>
                 {isCollapsed && (
                   <TooltipContent side="right">
                     {item.name}
                   </TooltipContent>
                 )}
               </Tooltip>
            </li>
          ))}
        </ul>
      </nav>
      
      <div className={cn(
        "mt-auto border-t border-cream/10 transition-all duration-300",
        isCollapsed ? 'px-2 py-3' : 'px-4 py-3'
      )}>
        <Tooltip>
          <TooltipTrigger asChild>
            <button 
              onClick={onLogout}
              className={cn(
                "group flex h-11 w-full items-center rounded-md text-sm transition-colors duration-150 ease-in-out text-army-tan hover:bg-red-800/50 hover:text-red-300",
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