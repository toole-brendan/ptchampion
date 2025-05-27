import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"
import { Label } from "./label"

const textFieldVariants = cva(
  "flex w-full rounded-input border bg-white px-3 py-2 text-sm ring-offset-background transition-all duration-base file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "border-tactical-gray/30 focus:border-brass-gold",
        error: "border-error focus:ring-error",
        success: "border-success focus:ring-success",
      },
      size: {
        small: "h-8 text-xs",
        medium: "h-10 text-sm",
        large: "h-12 text-base",
      }
    },
    defaultVariants: {
      variant: "default",
      size: "medium",
    },
  }
)

export interface TextFieldProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'size'>,
    VariantProps<typeof textFieldVariants> {
  label?: string
  helperText?: string
  error?: boolean
  errorMessage?: string
  required?: boolean
  fullWidth?: boolean
  icon?: React.ReactNode
  keyboardType?: string
}

const TextField = React.forwardRef<HTMLInputElement, TextFieldProps>(
  ({ 
    className, 
    variant, 
    size, 
    label,
    helperText,
    error,
    errorMessage,
    required,
    fullWidth,
    id,
    icon,
    keyboardType,
    ...props 
  }, ref) => {
    const inputId = id || React.useId()
    const computedVariant = error ? 'error' : variant
    
    const input = (
      <div className="relative w-full">
        {icon && (
          <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-tactical-gray">
            {icon}
          </div>
        )}
        <input
          id={inputId}
          className={cn(
            textFieldVariants({ variant: computedVariant, size }),
            fullWidth && "w-full",
            icon && "pl-10",
            className
          )}
          ref={ref}
          aria-invalid={error}
          aria-describedby={
            helperText || errorMessage ? `${inputId}-helper` : undefined
          }
          {...props}
        />
      </div>
    )
    
    if (!label && !helperText && !errorMessage) {
      return input
    }
    
    return (
      <div className={cn("space-y-2", fullWidth && "w-full")}>
        {label && (
          <Label 
            htmlFor={inputId} 
            required={required}
            variant={error ? 'error' : 'default'}
          >
            {label}
          </Label>
        )}
        {input}
        {(helperText || errorMessage) && (
          <p 
            id={`${inputId}-helper`}
            className={cn(
              "text-xs",
              error ? "text-error" : "text-muted-foreground"
            )}
          >
            {errorMessage || helperText}
          </p>
        )}
      </div>
    )
  }
)

TextField.displayName = "TextField"

// Military-style input variant
const MilitaryTextField = React.forwardRef<HTMLInputElement, TextFieldProps>(
  ({ className, ...props }, ref) => {
    return (
      <TextField
        ref={ref}
        className={cn(
          "uppercase tracking-wider font-mono",
          "border-2 border-dashed border-tactical-gray/50",
          "focus:border-solid focus:border-brass-gold",
          className
        )}
        {...props}
      />
    )
  }
)

MilitaryTextField.displayName = "MilitaryTextField"

export { TextField, MilitaryTextField, textFieldVariants }
