import React from 'react';
import {
  Home,
  User,
  Award,
  Settings,
  History,
} from 'lucide-react';

// Custom Icons
interface IconProps extends React.SVGProps<SVGSVGElement> {
  size?: number;
}

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

export const NAV_ITEMS = [
  { name: 'Dashboard', path: '/', icon: Home },
  { name: 'Exercises', path: '/exercises', icon: DumbbellIcon },
  { name: 'History', path: '/history', icon: History },
  { name: 'Leaderboard', path: '/leaderboard', icon: Award },
  { name: 'Profile', path: '/profile', icon: User },
  { name: 'Settings', path: '/settings', icon: Settings },
] as const; 