import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  Home as HomeIcon, 
  User as UserIcon,
  Trophy as TrophyIcon,
  ChevronLeft as ChevronLeftIcon,
  ChevronRight as ChevronRightIcon,
  LogOut as LogOutIcon
} from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

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
}

const Sidebar: React.FC<SidebarProps> = ({ username, onLogout }) => {
  const location = useLocation();
  const [isCollapsed, setIsCollapsed] = useState(false);
  
  const isActive = (path: string) => location.pathname === path;
  
  const navItems = [
    { name: 'Dashboard', path: '/', icon: HomeIcon },
    { name: 'Exercises', path: '/exercises', icon: DumbbellIcon },
    { name: 'History', path: '/history', icon: HistoryIcon },
    { name: 'Leaderboard', path: '/leaderboard', icon: TrophyIcon },
    { name: 'Profile', path: '/profile', icon: UserIcon },
  ];

  const toggleSidebar = () => {
    setIsCollapsed(!isCollapsed);
  };
  
  // Get user initials for avatar
  const userInitial = username ? username.charAt(0).toUpperCase() : '?';
  
  return (
    <TooltipProvider delayDuration={100}>
      <aside 
        className={`bg-gray-900 text-gray-200 transition-all duration-300 ease-in-out flex flex-col h-screen ${
          isCollapsed ? 'w-20' : 'w-64'
        }`}
      >
        <div className={`flex items-center border-b border-gray-800 transition-all duration-300 ${isCollapsed ? 'px-2 justify-center h-16' : 'px-4 justify-between h-16'}`}>
          {!isCollapsed && <h2 className="text-xl font-bold text-white">PT Champion</h2>}
          <Tooltip>
            <TooltipTrigger asChild>
              <button 
                onClick={toggleSidebar}
                className="p-2 rounded-md hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-opacity-50 text-gray-400 hover:text-white"
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
        
        <div className={`border-b border-gray-800 transition-all duration-300 ${isCollapsed ? 'py-4 px-2' : 'py-4 px-4'}`}>
          <Tooltip>
            <TooltipTrigger asChild>
              <div className={`flex items-center ${isCollapsed ? 'justify-center' : ''}`}>
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center text-sm font-semibold text-white">
                  {userInitial}
                </div>
                {!isCollapsed && (
                  <span className="ml-3 text-sm font-medium text-white truncate">
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
        
        <nav className="flex-grow mt-4">
          <ul className={`space-y-1 ${isCollapsed ? 'px-2' : 'px-4'}`}>
            {navItems.map((item) => (
              <li key={item.path}>
                 <Tooltip>
                   <TooltipTrigger asChild>
                      <Link
                        to={item.path}
                        className={`flex items-center h-11 rounded-md transition-colors duration-150 ease-in-out group ${
                          isActive(item.path)
                            ? 'bg-indigo-600 text-white font-medium'
                            : 'text-gray-400 hover:bg-gray-800 hover:text-white'
                        } ${isCollapsed ? 'justify-center px-0' : 'px-3'}`}
                      >
                        <item.icon className={`w-5 h-5 flex-shrink-0 ${isCollapsed ? '' : 'mr-3'}`} /> 
                        {!isCollapsed && <span className="text-sm">{item.name}</span>}
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
        
        <div className={`border-t border-gray-800 mt-auto transition-all duration-300 ${isCollapsed ? 'px-2 py-3' : 'px-4 py-3'}`}>
          <Tooltip>
            <TooltipTrigger asChild>
              <button 
                onClick={onLogout}
                className={`flex items-center w-full h-11 rounded-md text-sm transition-colors duration-150 ease-in-out group text-gray-400 hover:bg-red-800/50 hover:text-red-300 ${
                  isCollapsed ? 'justify-center px-0' : 'px-3'
                }`}
              >
                <LogOutIcon className={`w-5 h-5 flex-shrink-0 ${isCollapsed ? '' : 'mr-3'}`} />
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
    </TooltipProvider>
  );
};

export default Sidebar; 