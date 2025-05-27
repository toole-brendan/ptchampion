import * as React from "react"
import { ArrowLeft } from "lucide-react"
import { Button } from "./button"
import { cn } from "@/lib/utils"

interface MilitarySettingsHeaderProps {
  title: string
  description: string
  onBack?: () => void
  className?: string
}

export const MilitarySettingsHeader: React.FC<MilitarySettingsHeaderProps> = ({
  title,
  description,
  onBack,
  className
}) => {
  return (
    <div className={cn("space-y-4 pt-5 pb-5", className)}>
      <div className="flex items-center justify-between">
        <h1 className="font-heading text-[32px] font-bold uppercase tracking-[2px] text-deep-ops">
          {title}
        </h1>
        
        {onBack && (
          <Button
            variant="outline"
            size="small"
            onClick={onBack}
            className="flex items-center gap-1.5 bg-deep-ops text-brass-gold border-none hover:bg-deep-ops/90 px-3 py-2 h-auto"
          >
            <ArrowLeft className="w-3 h-3" />
            <span className="text-xs font-semibold uppercase">Back</span>
          </Button>
        )}
      </div>
      
      {/* Brass accent line */}
      <div className="w-[120px] h-[1.5px] bg-brass-gold" />
      
      <p className="font-heading text-base font-normal uppercase tracking-[1.5px] text-deep-ops">
        {description}
      </p>
    </div>
  )
} 