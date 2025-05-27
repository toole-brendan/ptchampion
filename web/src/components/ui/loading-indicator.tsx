import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const loadingIndicatorVariants = cva(
  "inline-flex items-center justify-center",
  {
    variants: {
      size: {
        small: "w-4 h-4",
        medium: "w-8 h-8",
        large: "w-12 h-12",
      },
      variant: {
        spinner: "",
        dots: "",
        pulse: "",
        military: "",
      }
    },
    defaultVariants: {
      size: "medium",
      variant: "spinner",
    },
  }
)

export interface LoadingIndicatorProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof loadingIndicatorVariants> {
  label?: string
}

const LoadingIndicator = React.forwardRef<HTMLDivElement, LoadingIndicatorProps>(
  ({ className, size, variant, label, ...props }, ref) => {
    const renderIndicator = () => {
      switch (variant) {
        case "spinner":
          return (
            <svg
              className="animate-spin"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
              />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
          )
          
        case "dots":
          return (
            <div className="flex space-x-1">
              <div className="w-2 h-2 bg-current rounded-full animate-bounce [animation-delay:-0.3s]" />
              <div className="w-2 h-2 bg-current rounded-full animate-bounce [animation-delay:-0.15s]" />
              <div className="w-2 h-2 bg-current rounded-full animate-bounce" />
            </div>
          )
          
        case "pulse":
          return (
            <div className="relative">
              <div className="w-full h-full bg-brass-gold rounded-full animate-ping absolute opacity-75" />
              <div className="w-full h-full bg-brass-gold rounded-full relative" />
            </div>
          )
          
        case "military":
          return (
            <div className="relative">
              <div className="absolute inset-0 border-2 border-t-brass-gold border-r-transparent border-b-transparent border-l-transparent rounded-full animate-spin" />
              <div className="absolute inset-1 border-2 border-t-transparent border-r-tactical-gray border-b-transparent border-l-transparent rounded-full animate-spin [animation-direction:reverse] [animation-duration:1.5s]" />
              <div className="absolute inset-2 border-2 border-t-transparent border-r-transparent border-b-army-tan border-l-transparent rounded-full animate-spin [animation-duration:2s]" />
            </div>
          )
          
        default:
          return null
      }
    }
    
    return (
      <div
        ref={ref}
        className={cn("inline-flex flex-col items-center gap-2", className)}
        role="status"
        aria-live="polite"
        {...props}
      >
        <div className={cn(loadingIndicatorVariants({ size, variant }))}>
          {renderIndicator()}
        </div>
        {label && (
          <span className="text-sm text-tactical-gray">{label}</span>
        )}
        <span className="sr-only">Loading...</span>
      </div>
    )
  }
)

LoadingIndicator.displayName = "LoadingIndicator"

// Full page loading overlay
const LoadingOverlay = React.forwardRef<
  HTMLDivElement,
  LoadingIndicatorProps & { fullScreen?: boolean }
>(({ fullScreen, className, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn(
        "flex items-center justify-center bg-background/80 backdrop-blur-sm",
        fullScreen ? "fixed inset-0 z-50" : "absolute inset-0",
        className
      )}
    >
      <LoadingIndicator variant="military" size="large" {...props} />
    </div>
  )
})

LoadingOverlay.displayName = "LoadingOverlay"

// Skeleton loader for content placeholders
const SkeletonLoader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement> & {
    height?: string | number
    width?: string | number
    variant?: "text" | "circular" | "rectangular"
  }
>(({ className, height, width, variant = "rectangular", ...props }, ref) => {
  const variantClasses = {
    text: "h-4 w-full",
    circular: "rounded-full",
    rectangular: "rounded-md",
  }
  
  return (
    <div
      ref={ref}
      className={cn(
        "animate-shimmer bg-gradient-to-r from-tactical-gray/10 via-tactical-gray/20 to-tactical-gray/10 bg-[length:700px_100%]",
        variantClasses[variant],
        className
      )}
      style={{
        height: height,
        width: width,
      }}
      {...props}
    />
  )
})

SkeletonLoader.displayName = "SkeletonLoader"

export { LoadingIndicator, LoadingOverlay, SkeletonLoader, loadingIndicatorVariants }
