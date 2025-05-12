import * as React from "react"
import * as SeparatorPrimitive from "@radix-ui/react-separator"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "@/lib/utils"

const separatorVariants = cva(
  "shrink-0 transition-colors",
  {
    variants: {
      variant: {
        default: "bg-cream-dark",
        subtle: "bg-cream-dark opacity-50",
        accent: "bg-brass-gold bg-opacity-20",
        accent2: "bg-army-tan opacity-30",
        muted: "bg-deep-ops opacity-10",
      },
      size: {
        default: "h-px",
        thin: "h-[0.5px]",
        thick: "h-[2px]",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    }
  }
);

export interface SeparatorProps 
  extends React.ComponentPropsWithoutRef<typeof SeparatorPrimitive.Root>,
    VariantProps<typeof separatorVariants> {
  label?: string;
}

const Separator = React.forwardRef<
  React.ElementRef<typeof SeparatorPrimitive.Root>,
  SeparatorProps
>(
  (
    { className, orientation = "horizontal", decorative = true, variant, size, label, ...props },
    ref
  ) => (
    <div className={cn("flex items-center w-full", orientation === "vertical" && "flex-col h-full")}>
      {label && orientation === "horizontal" ? (
        <div className="flex w-full items-center gap-3">
          <SeparatorPrimitive.Root
            ref={ref}
            decorative={decorative}
            orientation={orientation}
            className={cn(
              separatorVariants({ variant, size }),
              orientation === "horizontal" ? "w-full" : "h-full w-[1px]",
              className
            )}
            {...props}
          />
          <span className="shrink-0 whitespace-nowrap text-xs font-medium text-tactical-gray">{label}</span>
          <SeparatorPrimitive.Root
            decorative={decorative}
            orientation={orientation}
            className={cn(
              separatorVariants({ variant, size }),
              orientation === "horizontal" ? "w-full" : "h-full w-[1px]",
              className
            )}
            {...props}
          />
        </div>
      ) : (
        <SeparatorPrimitive.Root
          ref={ref}
          decorative={decorative}
          orientation={orientation}
          className={cn(
            separatorVariants({ variant, size }),
            orientation === "horizontal" ? "w-full" : "h-full w-[1px]",
            className
          )}
          {...props}
        />
      )}
    </div>
  )
)
Separator.displayName = SeparatorPrimitive.Root.displayName

export { Separator }
