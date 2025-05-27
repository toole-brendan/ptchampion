import * as React from "react"
import { cn } from "@/lib/utils"

interface PTChampionHeaderProps {
  className?: string
  title?: string
  subtitle?: string
}

const PTChampionHeader: React.FC<PTChampionHeaderProps> = ({
  className,
  title = "PT Champion",
  subtitle = "Fitness Evaluation System"
}) => {
  return (
    <div className={cn("flex flex-col items-center text-center py-5 pb-8", className)}>
      {/* Large PT Champion title */}
      <h1 
        className="font-heading text-5xl font-black uppercase text-brass-gold mb-6"
        style={{ letterSpacing: '2px' }}
      >
        {title}
      </h1>
      
      {/* Gold separator line */}
      <div className="w-30 h-0.5 bg-brass-gold mb-6"></div>
      
      {/* Subtitle */}
      <p 
        className="font-heading text-lg font-normal uppercase text-deep-ops"
        style={{ letterSpacing: '1.5px' }}
      >
        {subtitle}
      </p>
    </div>
  )
}

export { PTChampionHeader } 