import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const sectionContainerVariants = cva(
  "w-full",
  {
    variants: {
      spacing: {
        none: "",
        small: "space-y-sm",
        medium: "space-y-md",
        large: "space-y-lg",
        section: "space-y-section",
      },
      padding: {
        none: "",
        small: "p-sm",
        medium: "p-md",
        large: "p-lg",
        content: "p-content",
        adaptive: "p-adaptive",
      },
      layout: {
        stack: "flex flex-col",
        row: "flex flex-row items-center",
        grid: "grid",
      }
    },
    defaultVariants: {
      spacing: "medium",
      padding: "none",
      layout: "stack",
    },
  }
)

export interface SectionContainerProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof sectionContainerVariants> {
  as?: React.ElementType
  maxWidth?: "sm" | "md" | "lg" | "xl" | "full"
  center?: boolean
  title: string
  description?: string
  headerClassName?: string
  contentClassName?: string
  showDivider?: boolean
}

const SectionContainer = React.forwardRef<HTMLDivElement, SectionContainerProps>(
  ({ 
    className, 
    spacing, 
    padding, 
    layout,
    as: Component = "div",
    maxWidth,
    center,
    children,
    title,
    description,
    headerClassName,
    contentClassName,
    showDivider = true,
    ...props 
  }, ref) => {
    const maxWidthClasses = {
      sm: "max-w-sm",
      md: "max-w-md",
      lg: "max-w-lg",
      xl: "max-w-xl",
      full: "max-w-full",
    }
    
    return (
      <Component
        ref={ref}
        className={cn(
          sectionContainerVariants({ spacing, padding, layout }),
          maxWidth && maxWidthClasses[maxWidth],
          center && "mx-auto",
          className
        )}
        {...props}
      >
        {/* Dark header matching iOS pattern */}
        <div className={cn("p-4 bg-deep-ops", headerClassName)}>
          <h2 className="font-heading text-2xl font-bold uppercase tracking-wider text-brass-gold mb-1">
            {title}
          </h2>
          {showDivider && (
            <div className="h-px w-30 bg-brass-gold opacity-30 mb-1"></div>
          )}
          {description && (
            <p className="text-sm font-medium uppercase tracking-wide text-brass-gold">
              {description}
            </p>
          )}
        </div>
        
        {/* Light content area */}
        <div className={cn("p-4 bg-cream-dark", contentClassName)}>
          {children}
        </div>
      </Component>
    )
  }
)

SectionContainer.displayName = "SectionContainer"

// Specialized section containers
const HeroSection = React.forwardRef<HTMLDivElement, SectionContainerProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <SectionContainer
        ref={ref}
        className={cn(
          "min-h-[400px] flex items-center justify-center text-center",
          "bg-gradient-to-b from-deep-ops to-command-black",
          "text-cream",
          className
        )}
        padding="large"
        {...props}
      >
        {children}
      </SectionContainer>
    )
  }
)

HeroSection.displayName = "HeroSection"

const ContentSection = React.forwardRef<HTMLDivElement, SectionContainerProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <SectionContainer
        ref={ref}
        as="section"
        className={cn("py-section", className)}
        spacing="large"
        {...props}
      >
        {children}
      </SectionContainer>
    )
  }
)

ContentSection.displayName = "ContentSection"

const GridSection = React.forwardRef<HTMLDivElement, SectionContainerProps & {
  columns?: number | { sm?: number; md?: number; lg?: number }
  gap?: "small" | "medium" | "large"
}>(
  ({ className, children, columns = 1, gap = "medium", ...props }, ref) => {
    const gapClasses = {
      small: "gap-sm",
      medium: "gap-md",
      large: "gap-lg",
    }
    
    const getGridClasses = () => {
      if (typeof columns === "number") {
        return `grid-cols-${columns}`
      }
      
      let classes = "grid-cols-1"
      if (columns.sm) classes += ` sm:grid-cols-${columns.sm}`
      if (columns.md) classes += ` md:grid-cols-${columns.md}`
      if (columns.lg) classes += ` lg:grid-cols-${columns.lg}`
      
      return classes
    }
    
    return (
      <SectionContainer
        ref={ref}
        layout="grid"
        className={cn(
          getGridClasses(),
          gapClasses[gap],
          className
        )}
        {...props}
      >
        {children}
      </SectionContainer>
    )
  }
)

GridSection.displayName = "GridSection"

export { 
  SectionContainer, 
  HeroSection, 
  ContentSection, 
  GridSection,
  sectionContainerVariants 
}
