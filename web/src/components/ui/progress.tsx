import * as React from "react";
import * as ProgressPrimitive from "@radix-ui/react-progress";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const progressVariants = cva(
  "relative overflow-hidden rounded-full bg-cream-dark",
  {
    variants: {
      variant: {
        default: "bg-cream-dark",
        ghost: "border-brass-gold/20 border bg-transparent",
      },
      size: {
        default: "h-2",
        sm: "h-1",
        lg: "h-3",
        xl: "h-4",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    }
  }
);

const indicatorVariants = cva(
  "size-full flex-1 transition-all",
  {
    variants: {
      variant: {
        default: "bg-brass-gold",
        success: "bg-success",
        warning: "bg-warning",
        danger: "bg-error",
        info: "bg-info",
      },
    },
    defaultVariants: {
      variant: "default",
    }
  }
);

export interface ProgressProps 
  extends React.ComponentPropsWithoutRef<typeof ProgressPrimitive.Root>,
    VariantProps<typeof progressVariants> {
  indicatorVariant?: VariantProps<typeof indicatorVariants>["variant"];
  showValue?: boolean;
  formatValue?: (value: number) => string;
  label?: string;
}

/**
 * Progress component for displaying progress bars
 * Uses Radix UI Progress primitive with iOS-inspired styling
 */
const Progress = React.forwardRef<
  React.ElementRef<typeof ProgressPrimitive.Root>,
  ProgressProps
>(({ 
  className, 
  value, 
  variant, 
  size, 
  indicatorVariant,
  showValue = false,
  formatValue,
  label,
  ...props 
}, ref) => {
  const displayValue = value || 0;
  const formattedValue = formatValue 
    ? formatValue(displayValue) 
    : `${displayValue.toFixed(0)}%`;

  return (
    <div className="w-full">
      {(label || showValue) && (
        <div className="mb-1 flex justify-between">
          {label && (
            <span className="font-semibold text-sm text-tactical-gray">
              {label}
            </span>
          )}
          {showValue && (
            <span className="font-mono text-sm text-command-black">
              {formattedValue}
            </span>
          )}
        </div>
      )}
      <ProgressPrimitive.Root
        ref={ref}
        className={cn(
          progressVariants({ variant, size }),
          className
        )}
        value={displayValue}
        {...props}
      >
        <ProgressPrimitive.Indicator
          className={cn(indicatorVariants({ variant: indicatorVariant }))}
          style={{ transform: `translateX(-${100 - displayValue}%)` }}
        />
      </ProgressPrimitive.Root>
    </div>
  );
});

Progress.displayName = "Progress";

export { Progress }; 