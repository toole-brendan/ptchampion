import React from 'react';
import { Icons } from '@/assets/icons';
import { cn } from '@/lib/utils';
import { LucideIcon } from 'lucide-react';

export interface IconProps extends React.HTMLAttributes<HTMLElement> {
  icon: string | LucideIcon;
  className?: string;
}

/**
 * Icon component that can render either a string icon name from our custom icons
 * or a Lucide icon component directly
 */
export const Icon: React.FC<IconProps> = ({ icon, className, ...props }) => {
  // If icon is a string, render from our custom icons
  if (typeof icon === 'string') {
    const IconComponent = Icons[icon as keyof typeof Icons];
    
    if (!IconComponent) {
      console.warn(`Icon "${icon}" not found in icon library`);
      return null;
    }
    
    return <IconComponent className={cn('size-4', className)} {...props} />;
  }
  
  // If icon is a LucideIcon component, render it directly
  const IconComponent = icon;
  return <IconComponent className={cn('size-4', className)} {...props} />;
};

export default Icon; 