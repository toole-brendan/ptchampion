import * as React from "react"
import { cn } from "@/lib/utils"

interface MilitaryCardBackgroundProps {
  className?: string
  cornerSize?: number
  borderColor?: string
  borderOpacity?: number
}

export const MilitaryCardBackground: React.FC<MilitaryCardBackgroundProps> = ({
  className,
  cornerSize = 15,
  borderColor = "var(--color-tactical-gray)",
  borderOpacity = 0.5
}) => {
  return (
    <div className={cn("absolute inset-0 overflow-hidden", className)}>
      <svg 
        className="absolute inset-0 w-full h-full" 
        preserveAspectRatio="none"
        viewBox="0 0 100 100"
      >
        {/* Background fill */}
        <rect 
          x="0" 
          y="0" 
          width="100" 
          height="100" 
          fill="var(--color-card-background)"
        />
        
        {/* Corner cutouts */}
        <g fill="var(--color-background)">
          {/* Top-left corner */}
          <polygon points={`0,0 ${cornerSize},0 0,${cornerSize}`} />
          
          {/* Top-right corner */}
          <polygon points={`${100-cornerSize},0 100,0 100,${cornerSize}`} />
          
          {/* Bottom-right corner */}
          <polygon points={`100,${100-cornerSize} 100,100 ${100-cornerSize},100`} />
          
          {/* Bottom-left corner */}
          <polygon points={`0,${100-cornerSize} ${cornerSize},100 0,100`} />
        </g>
        
        {/* Border outline */}
        <g 
          fill="none" 
          stroke={borderColor} 
          strokeWidth="1" 
          strokeOpacity={borderOpacity}
        >
          {/* Top edge with gap */}
          <line x1={cornerSize} y1="0" x2={100-cornerSize} y2="0" />
          
          {/* Right edge with gap */}
          <line x1="100" y1={cornerSize} x2="100" y2={100-cornerSize} />
          
          {/* Bottom edge with gap */}
          <line x1={100-cornerSize} y1="100" x2={cornerSize} y2="100" />
          
          {/* Left edge with gap */}
          <line x1="0" y1={100-cornerSize} x2="0" y2={cornerSize} />
          
          {/* Diagonal corner connectors */}
          <line x1="0" y1={cornerSize} x2={cornerSize} y2="0" />
          <line x1={100-cornerSize} y1="0" x2="100" y2={cornerSize} />
          <line x1="100" y1={100-cornerSize} x2={100-cornerSize} y2="100" />
          <line x1={cornerSize} y1="100" x2="0" y2={100-cornerSize} />
        </g>
      </svg>
    </div>
  )
}

// Alternative CSS-only implementation using clip-path
export const MilitaryCardClipPath: React.FC<{
  children: React.ReactNode
  className?: string
  cornerSize?: number
}> = ({ children, className, cornerSize = 15 }) => {
  const clipPath = `polygon(
    ${cornerSize}px 0,
    100% 0,
    100% calc(100% - ${cornerSize}px),
    calc(100% - ${cornerSize}px) 100%,
    0 100%,
    0 ${cornerSize}px
  )`
  
  return (
    <div 
      className={cn("relative", className)}
      style={{ clipPath }}
    >
      {children}
    </div>
  )
}
