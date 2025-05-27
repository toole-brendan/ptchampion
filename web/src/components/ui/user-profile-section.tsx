import * as React from "react"
import { ChevronRight } from "lucide-react"
import { cn } from "@/lib/utils"
import { IOSStatCard } from "./ios-stat-card"

interface StatData {
  title: string
  value: string
  subtitle?: string
  icon: React.ReactNode
  onPress?: () => void
}

interface UserProfileSectionProps {
  className?: string
  userName: string
  totalWorkouts: number
  stats: StatData[]
  onViewProfile?: () => void
}

const UserProfileSection: React.FC<UserProfileSectionProps> = ({
  className,
  userName,
  totalWorkouts,
  stats,
  onViewProfile
}) => {
  return (
    <div className={cn("overflow-hidden rounded-lg shadow-card", className)}>
      {/* Header with user name and view profile button */}
      <div className="p-4 bg-deep-ops">
        <div className="flex items-center justify-between mb-1">
          <h2 className="font-heading text-2xl font-bold uppercase tracking-wider text-brass-gold">
            {userName.toUpperCase()}
          </h2>
          
          {onViewProfile && (
            <button
              onClick={onViewProfile}
              className="flex items-center gap-2 px-4 py-2 border border-brass-gold rounded-md hover:bg-brass-gold hover:bg-opacity-10 transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-brass-gold focus:ring-offset-2 focus:ring-offset-deep-ops"
            >
              <span className="text-sm font-medium text-brass-gold">VIEW PROFILE</span>
              <ChevronRight className="w-3 h-3 text-brass-gold" />
            </button>
          )}
        </div>
        
        <div className="h-px w-30 bg-brass-gold opacity-30 mb-1"></div>
        
        <p className="text-sm font-medium uppercase tracking-wide text-brass-gold">
          {totalWorkouts} Total Workouts Completed
        </p>
      </div>
      
      {/* Stats grid */}
      <div className="p-4 bg-cream-dark">
        <div className="grid grid-cols-2 gap-4">
          {stats.map((stat, index) => (
            <IOSStatCard
              key={stat.title}
              title={stat.title}
              value={stat.value}
              subtitle={stat.subtitle}
              icon={stat.icon}
              onPress={stat.onPress}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

export { UserProfileSection } 