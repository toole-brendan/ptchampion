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
      <div className="space-y-0">
        {rubricOptions.map((option, index) => (
          <div key={option.title}>
            <button
              onClick={option.onClick}
              className={cn(
                "flex items-center justify-between w-full py-3 px-4",
                "hover:bg-black hover:bg-opacity-5 transition-colors duration-150 bg-white",
                "focus:outline-none"
              )}
            >
              <span className="font-mono text-base font-medium uppercase text-command-black">
                {option.title}
              </span>
              <ChevronRight className="w-5 h-5 text-brass-gold" />
            </button>
            {index < rubricOptions.length - 1 && (
              <div className="h-px bg-gray-200 mx-4"></div>
            )}
          </div>
        ))}
      </div>
    </IOSSection>
  )
}

export { ScoringRubricSection } 