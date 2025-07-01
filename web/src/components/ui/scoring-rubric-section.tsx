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
      contentClassName="bg-white"
    >
      <div className="space-y-2">
        {rubricOptions.map((option, index) => (
          <button
            key={option.title}
            onClick={option.onClick}
            className={cn(
              "flex items-center justify-between w-full p-4 bg-white rounded-md",
              "hover:bg-brass-gold hover:bg-opacity-5 cursor-pointer",
              "focus:outline-none focus:bg-brass-gold focus:bg-opacity-10"
            )}
          >
            <span className="font-sans text-base font-medium uppercase text-command-black">
              {option.title}
            </span>
            <ChevronRight className="w-5 h-5 text-brass-gold" />
          </button>
        ))}
      </div>
    </IOSSection>
  )
}

export { ScoringRubricSection } 