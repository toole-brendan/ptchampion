import * as React from "react"
import { cn } from "@/lib/utils"

interface SettingsSectionProps {
  title: string
  description: string
  children: React.ReactNode
  className?: string
  variant?: "default" | "danger"
}

export const SettingsSection: React.FC<SettingsSectionProps> = ({
  title,
  description,
  children,
  className,
  variant = "default"
}) => {
  const headerColor = variant === "danger" ? "text-red-500" : "text-brass-gold"
  const borderColor = variant === "danger" ? "bg-red-500/30" : "bg-brass-gold/30"

  return (
    <div className={cn("overflow-hidden rounded-lg shadow-sm", className)}>
      {/* Dark header */}
      <div className="p-4 bg-deep-ops">
        <h2 className={cn("font-heading text-2xl font-bold uppercase mb-1", headerColor)}>
          {title}
        </h2>
        
        <div className={cn("h-px w-full mb-1", borderColor)} />
        
        <p className={cn("text-sm font-medium uppercase tracking-wide", headerColor)}>
          {description}
        </p>
      </div>
      
      {/* Light content area */}
      <div className="bg-cream-dark">
        {children}
      </div>
    </div>
  )
} 