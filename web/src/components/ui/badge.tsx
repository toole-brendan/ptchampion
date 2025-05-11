import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const badgeVariants = cva(
  "inline-flex items-center rounded-badge px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default: "bg-brass-gold text-cream",
        outline: "border border-brass-gold text-brass-gold",
        secondary: "bg-army-tan text-command-black",
        destructive: "bg-error text-white",
        success: "bg-success text-white",
        warning: "bg-warning text-deep-ops",
        info: "bg-info text-white",
        ghost: "bg-brass-gold/10 text-brass-gold",
      },
      size: {
        default: "h-6 text-xs",
        sm: "h-5 px-1.5 text-[10px]",
        lg: "h-7 px-3 text-sm",
      },
      pill: {
        true: "rounded-full",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
      pill: false,
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {
  icon?: React.ReactNode
}

function Badge({
  className,
  variant,
  size,
  pill,
  icon,
  children,
  ...props
}: BadgeProps) {
  return (
    <div
      className={cn(badgeVariants({ variant, size, pill, className }))}
      {...props}
    >
      {icon && <span className="mr-1">{icon}</span>}
      {children}
    </div>
  )
}

// Create specialized badges for common cases
function StatusBadge({ 
  status, 
  ...props 
}: Omit<BadgeProps, 'variant' | 'children'> & { 
  status: 'online' | 'offline' | 'away' | 'busy' | 'completed' | 'pending' | 'failed' 
}) {
  let variant: BadgeProps['variant']
  let text: string

  switch (status) {
    case 'online':
    case 'completed':
      variant = 'success'
      text = status === 'online' ? 'Online' : 'Completed'
      break
    case 'offline':
    case 'failed':
      variant = 'destructive'
      text = status === 'offline' ? 'Offline' : 'Failed'
      break
    case 'away':
    case 'pending':
      variant = 'warning'
      text = status === 'away' ? 'Away' : 'Pending'
      break
    case 'busy':
      variant = 'secondary'
      text = 'Busy'
      break
  }

  return <Badge variant={variant} pill {...props}>{text}</Badge>
}

export { Badge, StatusBadge, badgeVariants } 