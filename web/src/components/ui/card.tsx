import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "@/lib/utils"

const cardVariants = cva(
  "flex flex-col gap-md rounded-card bg-card text-card-foreground transition-all",
  {
    variants: {
      variant: {
        default: "shadow-small",
        interactive: "cursor-pointer shadow-small hover:-translate-y-1 hover:shadow-medium",
        elevated: "shadow-medium",
        panel: "rounded-panel shadow-medium",
        flush: "rounded-none shadow-none",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

interface CardProps extends React.ComponentProps<"div">, 
  VariantProps<typeof cardVariants> {}

function Card({ className, variant, ...props }: CardProps) {
  return (
    <div
      data-slot="card"
      className={cn(cardVariants({ variant, className }))}
      {...props}
    />
  )
}

function CardHeader({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-header"
      className={cn(
        "grid auto-rows-min grid-rows-[auto_auto] items-start gap-2 p-md has-data-[slot=card-action]:grid-cols-[1fr_auto]",
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
      className={cn("font-heading text-heading4 font-bold leading-none", className)}
      {...props}
    />
  )
}

function CardDescription({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-description"
      className={cn("text-small text-text-secondary", className)}
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
      className={cn("p-md pt-0", className)}
      {...props}
    />
  )
}

function CardFooter({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div
      data-slot="card-footer"
      className={cn("flex items-center p-md pt-0", className)}
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
    <Card variant="interactive" className={cn("min-w-[150px]", className)} {...props}>
      <CardHeader className="pb-0">
        <div className="flex items-center justify-between">
          <CardTitle className="text-text-secondary text-small uppercase">{title}</CardTitle>
          {icon && <div className="text-brass-gold">{icon}</div>}
        </div>
      </CardHeader>
      <CardContent className="pt-sm">
        <div className="font-mono text-heading3 font-medium text-command-black">{value}</div>
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
      className={cn("p-md", className)} 
      onClick={onClick} 
      {...props}
    >
      <div className="flex flex-col items-center justify-center gap-2 py-md">
        <div className="flex items-start gap-3">
          <div className="flex size-12 items-center justify-center rounded-full bg-brass-gold bg-opacity-10 text-brass-gold">
            {icon}
          </div>
        </div>
        <div className="text-center font-semibold">{title}</div>
      </div>
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
  StatCard,
  QuickLinkCard,
  cardVariants
}
