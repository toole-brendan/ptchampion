import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const cardVariants = cva(
  "relative flex flex-col group gap-md rounded-card bg-cream text-card-foreground transition-all border",
  {
    variants: {
      variant: {
        default: "shadow-card border-transparent",
        interactive: 
          "shadow-card transition-transform duration-150 " +
          "hover:-translate-y-1 hover:shadow-card-hover " +
          "hover:border-brass-gold hover:border-opacity-40 " +
          "border-transparent",
        elevated: "shadow-medium border-transparent",
        panel: "rounded-panel shadow-small bg-cream-dark p-content border-transparent",
        flush: "rounded-none shadow-none border-none",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

interface CardProps extends React.ComponentProps<"div">, 
  VariantProps<typeof cardVariants> {
}

function Card({ 
  className, 
  variant, 
  ...props 
}: CardProps) {
  // Only add cursor-pointer when onClick is provided
  const isClickable = !!props.onClick;
  
  return (
    <div
      data-slot="card"
      className={cn(
        cardVariants({ variant, className }),
        isClickable && 'cursor-pointer'
      )}
      {...props}
    >
      {props.children}
    </div>
  )
}

function CardHeader({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-header"
      className={cn(
        "grid auto-rows-min grid-rows-[auto_auto] items-start gap-2 p-content has-data-[slot=card-action]:grid-cols-[1fr_auto]",
        className
      )}
      {...props}
    />
  )
}

function CardTitle({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-title"
      className={cn("font-heading text-heading4 tracking-wider uppercase", className)}
      {...props}
    />
  )
}

function CardDescription({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-description"
      className={cn("text-small text-tactical-gray", className)}
      {...props}
    />
  )
}

function CardAction({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-action"
      className={cn(
        "col-start-2 row-span-2 row-start-1 self-start justify-self-end",
        className
      )}
      {...props}
    />
  )
}

function CardContent({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-content"
      className={cn("p-content pt-0", className)}
      {...props}
    />
  )
}

function CardFooter({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-footer"
      className={cn("flex items-center p-content pt-0", className)}
      {...props}
    />
  )
}

function CardDivider({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-divider"
      className={cn("h-px w-16 bg-brass-gold my-2", className)}
      {...props}
    />
  )
}

// Composite components for quick use
function StatCard({ 
  title, 
  value, 
  icon, 
  className, 
  ...props 
}: { 
  title: React.ReactNode; 
  value: React.ReactNode; 
  icon?: React.ReactNode;
} & Omit<CardProps, 'children'>) {
  return (
    <Card 
      variant="interactive" 
      className={cn("min-w-[150px]", className)} 
      {...props}
    >
      <CardHeader className="pb-0">
        <div className="flex items-center justify-between">
          <CardTitle className="text-xs text-tactical-gray uppercase tracking-wider">{title}</CardTitle>
          {icon && <div className="text-brass-gold">{icon}</div>}
        </div>
      </CardHeader>
      <CardContent className="pt-sm">
        <div className="font-heading text-heading3 text-command-black">{value}</div>
      </CardContent>
    </Card>
  )
}

function QuickLinkCard({ 
  title, 
  icon, 
  onClick,
  className, 
  ...props 
}: { 
  title: React.ReactNode; 
  icon: React.ReactNode;
  onClick?: () => void;
} & Omit<CardProps, 'children' | 'variant'>) {
  return (
    <Card 
      variant="interactive" 
      className={cn("p-content", className)} 
      onClick={onClick}
      {...props}
    >
      <div className="flex flex-col items-center justify-center gap-2 py-md">
        <div className="flex size-12 items-center justify-center rounded-full bg-brass-gold bg-opacity-10 text-brass-gold">
          {icon}
        </div>
        <div className="text-center font-semibold">{title}</div>
      </div>
    </Card>
  )
}

// Panel with section header - useful for dashboard sections
function SectionCard({
  title,
  description,
  icon,
  children,
  className,
  headerClassName,
  contentClassName,
  showDivider = true,
  descriptionClassName,
  ...props
}: {
  title: React.ReactNode;
  description?: React.ReactNode;
  icon?: React.ReactNode;
  children: React.ReactNode;
  headerClassName?: string;
  contentClassName?: string;
  showDivider?: boolean;
  descriptionClassName?: string;
} & Omit<CardProps, 'children'>) {
  return (
    <Card
      variant="default"
      className={cn("overflow-hidden", className)}
      {...props}
    >
      <div className={cn("p-4 bg-deep-ops", headerClassName)}>
        <div className="flex items-center">
          {icon && <span className="mr-2 text-brass-gold">{icon}</span>}
          <h2 className="font-heading text-2xl uppercase tracking-wider text-brass-gold">
            {title}
          </h2>
        </div>
        {showDivider && <div className="h-px w-16 bg-brass-gold opacity-30 my-2"></div>}
        {description && (
          <p className={cn(
            "text-xs uppercase tracking-wide text-brass-gold",
            descriptionClassName
          )}>
            {description}
          </p>
        )}
      </div>
      <div className={cn("p-content", contentClassName ?? 'bg-cream-dark')}>
        {children}
      </div>
    </Card>
  )
}

// Welcome Card for the dashboard
function WelcomeCard({
  title = "PT Champion",
  subtitle = "Fitness Evaluation System",
  profileSection,
  className,
  ...props
}: {
  title?: React.ReactNode;
  subtitle?: React.ReactNode;
  profileSection?: React.ReactNode;
} & Omit<CardProps, 'children'>) {
  return (
    <Card
      variant="default"
      className={cn("p-content text-center", className)}
      {...props}
    >
      <h2 className="font-heading text-3xl md:text-4xl text-brass-gold tracking-wider uppercase">
        {title}
      </h2>
      <CardDivider className="mx-auto" />
      <p className="text-sm uppercase tracking-wide text-tactical-gray">
        {subtitle}
      </p>
      
      {profileSection && (
        <div className="bg-cream-dark rounded-md p-4 mt-6 text-left">
          {profileSection}
        </div>
      )}
    </Card>
  )
}

// Icon footer - useful for tutorial cards, feature cards, etc.
export const IconFooter = React.forwardRef<
  React.ElementRef<typeof CardFooter>,
  React.ComponentPropsWithoutRef<typeof CardFooter> & {
    icon: React.ReactNode;
    title: string;
    subtitle?: string;
  }
>(({ className, icon, title, subtitle, ...props }, ref) => (
  <CardFooter
    ref={ref}
    className={cn(className)}
    {...props}
  >
    <div className="flex flex-col items-center justify-center gap-2 py-md">
      <div className="flex size-12 items-center justify-center rounded-full bg-brass-gold bg-opacity-10 text-brass-gold">
        {icon}
      </div>
      <div className="text-center font-semibold">{title}</div>
      {subtitle && (
        <div className="text-center text-sm text-tactical-gray">{subtitle}</div>
      )}
    </div>
  </CardFooter>
));

export {
  Card,
  CardHeader,
  CardFooter,
  CardTitle,
  CardAction,
  CardDescription,
  CardContent,
  CardDivider,
  StatCard,
  QuickLinkCard,
  SectionCard,
  WelcomeCard,
  cardVariants
}
