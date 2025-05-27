import * as React from "react"
import { ChevronRight } from "lucide-react"
import { Switch } from "./switch"
import { cn } from "@/lib/utils"

interface BaseSettingsRowProps {
  icon: React.ReactNode
  title: string
  description: string
  className?: string
  disabled?: boolean
}

interface SettingsToggleRowProps extends BaseSettingsRowProps {
  checked: boolean
  onCheckedChange: (checked: boolean) => void
}

interface SettingsActionRowProps extends BaseSettingsRowProps {
  onClick: () => void
  value?: string
}

export const SettingsToggleRow: React.FC<SettingsToggleRowProps> = ({
  icon,
  title,
  description,
  checked,
  onCheckedChange,
  className,
  disabled = false
}) => {
  return (
    <div className={cn("flex items-center px-5 py-4", className)}>
      {/* Icon in circular container */}
      <div className="flex-shrink-0 w-10 h-10 rounded-full bg-olive-mist/30 flex items-center justify-center mr-4">
        <div className="w-5 h-5 text-deep-ops flex items-center justify-center">
          {icon}
        </div>
      </div>
      
      {/* Content */}
      <div className="flex-1 min-w-0">
        <h3 className="font-medium text-base text-deep-ops uppercase">
          {title}
        </h3>
        <p className="text-sm text-tactical-gray mt-0.5 leading-tight">
          {description}
        </p>
      </div>
      
      {/* Toggle */}
      <Switch
        checked={checked}
        onCheckedChange={onCheckedChange}
        disabled={disabled}
        className="ml-4"
      />
    </div>
  )
}

export const SettingsActionRow: React.FC<SettingsActionRowProps> = ({
  icon,
  title,
  description,
  onClick,
  value,
  className,
  disabled = false
}) => {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={cn(
        "w-full flex items-center px-5 py-4 text-left transition-colors",
        "hover:bg-black/5 active:bg-black/10",
        disabled && "opacity-50 cursor-not-allowed",
        className
      )}
    >
      {/* Icon in circular container */}
      <div className="flex-shrink-0 w-10 h-10 rounded-full bg-olive-mist/30 flex items-center justify-center mr-4">
        <div className="w-5 h-5 text-deep-ops flex items-center justify-center">
          {icon}
        </div>
      </div>
      
      {/* Content */}
      <div className="flex-1 min-w-0">
        <h3 className="font-medium text-base text-deep-ops uppercase">
          {title}
        </h3>
        {description && (
          <p className="text-sm text-tactical-gray mt-0.5 leading-tight">
            {description}
          </p>
        )}
      </div>
      
      {/* Value or chevron */}
      {value ? (
        <span className="text-base text-tactical-gray ml-4">
          {value}
        </span>
      ) : (
        <ChevronRight className="w-3.5 h-3.5 text-deep-ops ml-4" />
      )}
    </button>
  )
}

export const SettingsDivider: React.FC<{ className?: string }> = ({ className }) => {
  return (
    <div className={cn("h-px bg-deep-ops/10 mx-5", className)} />
  )
} 