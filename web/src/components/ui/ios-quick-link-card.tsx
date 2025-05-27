import * as React from "react"
import { cn } from "@/lib/utils"

interface IOSQuickLinkCardProps extends React.ComponentProps<"button"> {
  title: string
  icon: React.ReactNode
  onPress?: () => void
}

const IOSQuickLinkCard = React.forwardRef<HTMLButtonElement, IOSQuickLinkCardProps>(
  ({ title, icon, onPress, className, ...props }, ref) => {
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
          "flex flex-col items-center justify-center gap-4 py-6 px-4",
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
        {/* Icon centered in circle container - matching iOS 72px */}
        <div className="flex items-center justify-center w-18 h-18 rounded-full bg-olive-mist bg-opacity-30">
          <div className="w-10 h-10 flex items-center justify-center text-deep-ops">
            {icon}
          </div>
        </div>
        
        {/* Text label - UPPERCASE with military styling */}
        <span className="font-mono text-base font-medium uppercase text-deep-ops text-center leading-tight">
          {title}
        </span>
      </button>
    )
  }
)

IOSQuickLinkCard.displayName = "IOSQuickLinkCard"

export { IOSQuickLinkCard } 