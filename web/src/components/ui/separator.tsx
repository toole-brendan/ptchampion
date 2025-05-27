import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const separatorVariants = cva(
  "shrink-0 bg-tactical-gray/30",
  {
    variants: {
      orientation: {
        horizontal: "h-[1px] w-full",
        vertical: "h-full w-[1px]",
      },
      variant: {
        default: "bg-tactical-gray/30",
        strong: "bg-tactical-gray/50",
        light: "bg-tactical-gray/20",
        brass: "bg-brass-gold/30",
        gradient: "bg-gradient-to-r from-transparent via-brass-gold/30 to-transparent",
      },
      decorative: {
        true: "",
        false: "",
      }
    },
    defaultVariants: {
      orientation: "horizontal",
      variant: "default",
      decorative: false,
    },
  }
)

export interface SeparatorProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof separatorVariants> {
  asChild?: boolean
}

const Separator = React.forwardRef<HTMLDivElement, SeparatorProps>(
  ({ 
    className, 
    orientation = "horizontal", 
    variant,
    decorative = true,
    ...props 
  }, ref) => {
    const ariaProps = decorative 
      ? { role: "none" } 
      : { role: "separator", "aria-orientation": orientation || undefined }
    
    return (
      <div
        ref={ref}
        className={cn(separatorVariants({ orientation, variant }), className)}
        {...ariaProps}
        {...props}
      />
    )
  }
)

Separator.displayName = "Separator"

// Military-style separator with notches
const MilitarySeparator = React.forwardRef<HTMLDivElement, SeparatorProps>(
  ({ className, ...props }, ref) => {
    return (
      <div 
        ref={ref} 
        className={cn("relative w-full h-[2px] my-4", className)}
        role="separator"
        {...props}
      >
        <div className="absolute inset-0 bg-tactical-gray/30" />
        <div className="absolute left-1/4 top-0 w-2 h-full bg-background" />
        <div className="absolute left-1/2 -translate-x-1/2 top-0 w-2 h-full bg-background" />
        <div className="absolute right-1/4 top-0 w-2 h-full bg-background" />
      </div>
    )
  }
)

MilitarySeparator.displayName = "MilitarySeparator"

// Decorative separator with brass accent
const BrassSeparator = React.forwardRef<HTMLDivElement, SeparatorProps>(
  ({ className, ...props }, ref) => {
    return (
      <div 
        ref={ref}
        className={cn("relative w-full h-[1px] my-4", className)}
        role="separator"
        {...props}
      >
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-brass-gold/50 to-transparent" />
        <div className="absolute left-1/2 -translate-x-1/2 -top-1 w-2 h-2 rotate-45 bg-brass-gold/50" />
      </div>
    )
  }
)

BrassSeparator.displayName = "BrassSeparator"

export { 
  Separator, 
  MilitarySeparator, 
  BrassSeparator,
  separatorVariants 
}
