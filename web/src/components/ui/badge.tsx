import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const badgeVariants = cva(
  "inline-flex items-center rounded-badge px-2 py-1 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "bg-brass-gold/20 text-brass-gold border-transparent",
        secondary:
          "bg-army-tan/20 text-tactical-gray border-transparent",
        destructive:
          "bg-error/10 text-error border-transparent",
        outline:
          "text-brass-gold border border-brass-gold",
        success:
          "bg-success/10 text-success border-transparent",
        warning:
          "bg-warning/10 text-warning border-transparent",
        info:
          "bg-info/10 text-info border-transparent",
        military:
          "bg-tactical-gray/10 text-tactical-gray border border-tactical-gray/30 uppercase tracking-wider font-mono",
      },
      size: {
        default: "px-2 py-0.5 text-xs",
        sm: "px-1.5 py-0.5 text-[10px]",
        lg: "px-3 py-1 text-sm",
      }
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

const Badge = React.forwardRef<HTMLDivElement, BadgeProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <div 
        ref={ref}
        className={cn(badgeVariants({ variant, size }), className)} 
        {...props} 
      />
    )
  }
)

Badge.displayName = "Badge"

// Specialized badge components
const RankBadge = React.forwardRef<HTMLDivElement, BadgeProps & { rank: string }>(
  ({ rank, className, ...props }, ref) => {
    return (
      <Badge
        ref={ref}
        variant="military"
        className={cn("border-2 border-dashed", className)}
        {...props}
      >
        {rank}
      </Badge>
    )
  }
)

RankBadge.displayName = "RankBadge"

const StatusBadge = React.forwardRef<HTMLDivElement, BadgeProps & { 
  status: "active" | "inactive" | "pending" | "completed" 
}>(
  ({ status, className, ...props }, ref) => {
    const statusConfig = {
      active: { variant: "success" as const, label: "Active" },
      inactive: { variant: "secondary" as const, label: "Inactive" },
      pending: { variant: "warning" as const, label: "Pending" },
      completed: { variant: "info" as const, label: "Completed" },
    }
    
    const config = statusConfig[status]
    
    return (
      <Badge
        ref={ref}
        variant={config.variant}
        className={className}
        {...props}
      >
        {config.label}
      </Badge>
    )
  }
)

StatusBadge.displayName = "StatusBadge"

const CountBadge = React.forwardRef<HTMLDivElement, BadgeProps & { 
  count: number
  max?: number
}>(
  ({ count, max = 99, className, ...props }, ref) => {
    const displayCount = count > max ? `${max}+` : count.toString()
    
    return (
      <Badge
        ref={ref}
        variant="default"
        size="sm"
        className={cn(
          "min-w-[20px] justify-center rounded-full px-1.5",
          className
        )}
        {...props}
      >
        {displayCount}
      </Badge>
    )
  }
)

CountBadge.displayName = "CountBadge"

export { Badge, RankBadge, StatusBadge, CountBadge, badgeVariants }
