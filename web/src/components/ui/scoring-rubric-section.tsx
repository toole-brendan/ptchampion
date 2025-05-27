import * as React from "react"
import { ChevronRight } from "lucide-react"
import { cn } from "@/lib/utils"
import { IOSSection } from "./ios-section"

interface RubricOption {
  title: string
  onClick: () => void
}

interface ScoringRubricSectionProps {
  className?: string
  rubricOptions: RubricOption[]
}

const ScoringRubricSection: React.FC<ScoringRubricSectionProps> = ({
  className,
  rubricOptions
}) => {
  return (
    <IOSSection
      title="Scoring Rubric"
      description="View scoring criteria for each exercise"
      className={className}
      contentClassName="p-0 bg-white"
    >
      <div className="divide-y divide-tactical-gray divide-opacity-20">
        {rubricOptions.map((option, index) => (
          <button
            key={option.title}
            onClick={option.onClick}
            className={cn(
              "flex items-center justify-between w-full py-4 px-5",
              "hover:bg-brass-gold hover:bg-opacity-5 transition-colors duration-150",
              "focus:outline-none focus:bg-brass-gold focus:bg-opacity-10"
            )}
          >
            <span className="font-mono text-base font-medium uppercase text-deep-ops">
              {option.title}
            </span>
            <ChevronRight className="w-3.5 h-3.5 text-deep-ops" />
          </button>
        ))}
      </div>
    </IOSSection>
  )
}

export { ScoringRubricSection } 