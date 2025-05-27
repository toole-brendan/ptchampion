import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const labelVariants = cva(
  "font-semibold peer-disabled:cursor-not-allowed peer-disabled:opacity-70",
  {
    variants: {
      size: {
        default: "text-sm",
        small: "text-xs",
        large: "text-base",
      },
      variant: {
        default: "text-command-black",
        secondary: "text-tactical-gray",
        error: "text-error",
        success: "text-success",
      }
    },
    defaultVariants: {
      size: "default",
      variant: "default",
    },
  }
)

export interface LabelProps
  extends React.LabelHTMLAttributes<HTMLLabelElement>,
    VariantProps<typeof labelVariants> {
  required?: boolean
}

const Label = React.forwardRef<HTMLLabelElement, LabelProps>(
  ({ className, size, variant, required, children, ...props }, ref) => {
    return (
      <label
        ref={ref}
        className={cn(labelVariants({ size, variant }), className)}
        {...props}
      >
        {children}
        {required && <span className="ml-1 text-error">*</span>}
      </label>
    )
  }
)

Label.displayName = "Label"

export { Label }
