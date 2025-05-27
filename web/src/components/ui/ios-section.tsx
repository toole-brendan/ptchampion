import * as React from "react"
import { cn } from "@/lib/utils"

interface IOSSectionProps extends React.ComponentProps<"div"> {
  title: string
  description?: string
  headerClassName?: string
  contentClassName?: string
  showDivider?: boolean
}

const IOSSection = React.forwardRef<HTMLDivElement, IOSSectionProps>(
  ({ 
    title, 
    description, 
    children, 
    className, 
    headerClassName, 
    contentClassName,
    showDivider = true,
    ...props 
  }, ref) => {
    return (
      <div
        ref={ref}
        className={cn("overflow-hidden rounded-lg shadow-card", className)}
        {...props}
      >
        {/* Dark header matching iOS pattern */}
        <div className={cn("p-4 bg-deep-ops", headerClassName)}>
          <h2 className="font-heading text-2xl font-bold uppercase tracking-wider text-brass-gold mb-1">
            {title}
          </h2>
          {showDivider && (
            <div className="h-px w-30 bg-brass-gold opacity-30 mb-1"></div>
          )}
          {description && (
            <p className="text-sm font-medium uppercase tracking-wide text-brass-gold">
              {description}
            </p>
          )}
        </div>
        
        {/* Light content area */}
        <div className={cn("p-4 bg-cream-dark", contentClassName)}>
          {children}
        </div>
      </div>
    )
  }
)

IOSSection.displayName = "IOSSection"

export { IOSSection } 