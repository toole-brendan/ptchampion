import * as React from "react"
import * as SwitchPrimitives from "@radix-ui/react-switch"

import { cn } from "@/lib/utils"

interface SwitchProps extends React.ComponentPropsWithoutRef<typeof SwitchPrimitives.Root> {
  label?: string
  description?: string
}

const Switch = React.forwardRef<
  React.ElementRef<typeof SwitchPrimitives.Root>,
  SwitchProps
>(({ className, label, description, ...props }, ref) => (
  <div className="flex items-center gap-3">
    <SwitchPrimitives.Root
      className={cn(
        "peer inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent shadow-small transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brass-gold focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-brass-gold data-[state=unchecked]:bg-tactical-gray/30",
        className
      )}
      {...props}
      ref={ref}
    >
      <SwitchPrimitives.Thumb
        className={cn(
          "pointer-events-none block h-5 w-5 rounded-full bg-cream shadow-medium ring-0 transition-transform data-[state=checked]:translate-x-5 data-[state=unchecked]:translate-x-0"
        )}
      />
    </SwitchPrimitives.Root>
    {(label || description) && (
      <div className="flex flex-col">
        {label && <span className="font-semibold text-sm">{label}</span>}
        {description && <span className="text-xs text-tactical-gray">{description}</span>}
      </div>
    )}
  </div>
))
Switch.displayName = SwitchPrimitives.Root.displayName

// Convenience component that provides a labeled toggle
const Toggle = React.forwardRef<
  React.ElementRef<typeof SwitchPrimitives.Root>,
  SwitchProps
>(({ label, description, className, ...props }, ref) => (
  <div className={cn("flex w-full items-center justify-between", className)}>
    <div className="flex flex-col">
      {label && <span className="font-semibold">{label}</span>}
      {description && <span className="text-small text-tactical-gray">{description}</span>}
    </div>
    <Switch ref={ref} {...props} />
  </div>
))
Toggle.displayName = "Toggle"

export { Switch, Toggle }
