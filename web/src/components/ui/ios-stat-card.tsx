import * as React from "react"
import { cn } from "@/lib/utils"

interface IOSStatCardProps extends React.ComponentProps<"button"> {
  title: string
  value: string
  subtitle?: string
  icon: React.ReactNode
  onPress?: () => void
}

const IOSStatCard = React.forwardRef<HTMLButtonElement, IOSStatCardProps>(
  ({ title, value, subtitle, icon, onPress, className, ...props }, ref) => {
    const [isPressed, setIsPressed] = React.useState(false)

    const handlePointerDown = () => {
      setIsPressed(true)
      // Light haptic feedback simulation
      if ('vibrate' in navigator) {
        navigator.vibrate(5)
      }
    }

    const handlePointerUp = () => {
      setIsPressed(false)
    }

    const handleClick = () => {
      if (onPress) {
        onPress()
      }
    }

    return (
      <button
        ref={ref}
        className={cn(
          "flex flex-col items-center justify-center gap-3 py-4 px-3",
          "w-full bg-white rounded-xl",
          "shadow-small transition-all duration-150",
          "hover:shadow-medium focus:outline-none focus:ring-2 focus:ring-brass-gold focus:ring-offset-2",
          isPressed && "scale-[0.98] brightness-[0.97]",
          className
        )}
        onPointerDown={handlePointerDown}
        onPointerUp={handlePointerUp}
        onPointerLeave={handlePointerUp}
        onClick={handleClick}
        {...props}
      >
        {/* Icon centered in circle container - matching iOS 60px */}
        <div className="flex items-center justify-center w-15 h-15 rounded-full bg-olive-mist bg-opacity-30">
          <div className="w-6 h-6 flex items-center justify-center text-deep-ops">
            {icon}
          </div>
        </div>
        
        {/* Stat value with title */}
        <div className="flex flex-col items-center gap-0.5">
          <span className="font-heading text-xl font-bold text-deep-ops">
            {value}
          </span>
          <span className="font-mono text-xs font-medium uppercase text-deep-ops text-opacity-80 text-center leading-tight">
            {title}
          </span>
          {subtitle && (
            <span className="text-xs text-tactical-gray text-center">
              {subtitle}
            </span>
          )}
        </div>
      </button>
    )
  }
)

IOSStatCard.displayName = "IOSStatCard"

export { IOSStatCard } 