import * as React from 'react';
import { cn } from '@/lib/utils';

interface SectionProps extends Omit<React.HTMLAttributes<HTMLDivElement>, 'title'> {
  children: React.ReactNode;
  title?: React.ReactNode;
  description?: React.ReactNode;
  icon?: React.ReactNode;
  action?: React.ReactNode;
}

/**
 * Section component for consistent section styling across the app
 * Can be used to wrap content in pages like Dashboard, Profile, etc.
 */
export function Section({
  children,
  title,
  description,
  icon,
  action,
  className,
  ...props
}: SectionProps) {
  return (
    <section
      className={cn('space-y-4', className)}
      {...props}
    >
      {(title || description || action) && (
        <div className="flex items-start justify-between">
          <div>
            {title && (
              <h2 className="font-heading text-heading3 uppercase tracking-wider text-brass-gold flex items-center">
                {icon && <span className="mr-2">{icon}</span>}
                {title}
              </h2>
            )}
            {description && (
              <p className="text-sm text-tactical-gray mt-1">{description}</p>
            )}
          </div>
          {action && (
            <div className="ml-4">{action}</div>
          )}
        </div>
      )}
      <div>{children}</div>
    </section>
  );
}

/**
 * SectionHeader component used for styled section headers
 */
export function SectionHeader({
  children,
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('section-header', className)}
      {...props}
    >
      {children}
    </div>
  );
}

/**
 * SectionContent component used for styled section content area
 */
export function SectionContent({
  children,
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('rounded-b-card bg-cream-dark p-content', className)}
      {...props}
    >
      {children}
    </div>
  );
} 