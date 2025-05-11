import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const inputVariants = cva(
  "flex w-full rounded-input border border-input bg-transparent px-md py-sm text-base shadow-small transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-tactical-gray focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brass-gold focus-visible:ring-opacity-50 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm",
  {
    variants: {
      variant: {
        default: "border-cream-dark",
        outline: "border-brass-gold/50",
        filled: "bg-cream-dark border-transparent",
        error: "border-error focus-visible:ring-error",
      },
      size: {
        default: "h-10",
        sm: "h-8 text-sm px-sm py-xs rounded-input",
        lg: "h-12 text-lg px-lg py-md rounded-input",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface InputProps 
  extends React.InputHTMLAttributes<HTMLInputElement>,
    VariantProps<typeof inputVariants> {
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
  error?: boolean
  label?: string
  helperText?: string
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ 
    className, 
    type, 
    variant, 
    size,
    leftIcon, 
    rightIcon, 
    error, 
    label, 
    helperText,
    ...props 
  }, ref) => {
    // Override variant if error is true
    const inputVariant = error ? "error" : variant

    return (
      <div className="w-full">
        {label && (
          <label className="mb-xs block font-sans text-small font-semibold text-tactical-gray">
            {label}
          </label>
        )}
        <div className="relative flex items-center">
          {leftIcon && (
            <div className="absolute left-md pointer-events-none text-tactical-gray">
              {leftIcon}
            </div>
          )}
          <input
            type={type}
            className={cn(
              inputVariants({ variant: inputVariant, size }),
              leftIcon && "pl-10",
              rightIcon && "pr-10",
              className
            )}
            ref={ref}
            aria-invalid={error}
            {...props}
          />
          {rightIcon && (
            <div className="absolute right-md pointer-events-none text-tactical-gray">
              {rightIcon}
            </div>
          )}
        </div>
        {helperText && (
          <p className={cn(
            "mt-xs text-xs", 
            error ? "text-error" : "text-tactical-gray"
          )}>
            {helperText}
          </p>
        )}
      </div>
    )
  }
)
Input.displayName = "Input"

// Create simpler input components for convenience
function TextField(props: Omit<InputProps, 'type'>) {
  return <Input type="text" {...props} />
}

function PasswordField(props: Omit<InputProps, 'type'>) {
  return <Input type="password" {...props} />
}

function EmailField(props: Omit<InputProps, 'type'>) {
  return <Input type="email" {...props} />
}

function NumberField(props: Omit<InputProps, 'type'>) {
  return <Input type="number" {...props} />
}

export { 
  Input, 
  TextField, 
  PasswordField, 
  EmailField, 
  NumberField,
  inputVariants 
}
