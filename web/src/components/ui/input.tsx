import * as React from "react"
import { cva } from "class-variance-authority"
import { cn } from "@/lib/utils"

const inputVariants = cva(
  "border-input flex w-full rounded-input border !bg-white px-md py-sm text-base shadow-small transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-tactical-gray focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brass-gold focus-visible:ring-opacity-50 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm",
  {
    variants: {
      variant: {
        default: "border-cream-dark !bg-white",
        outline: "border-brass-gold/50 !bg-white",
        filled: "border-transparent !bg-white",
        error: "border-error !bg-white focus-visible:ring-error",
      },
      inputSize: {
        default: "h-10",
        sm: "h-8 rounded-input px-sm py-xs text-sm",
        lg: "h-12 rounded-input px-lg py-md text-lg",
      },
    },
    defaultVariants: {
      variant: "default",
      inputSize: "default",
    },
  }
)

export interface InputProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'size'> {
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
  error?: boolean
  label?: string
  helperText?: string
  variant?: "default" | "outline" | "filled" | "error"
  inputSize?: "default" | "sm" | "lg"
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ 
    className, 
    type, 
    variant, 
    inputSize,
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
          <label className="mb-xs block font-sans text-small text-tactical-gray">
            {label}
          </label>
        )}
        <div className="relative flex items-center">
          {leftIcon && (
            <div className="pointer-events-none absolute left-md text-tactical-gray">
              {leftIcon}
            </div>
          )}
          <input
            type={type}
            className={cn(
              inputVariants({ 
                variant: inputVariant, 
                inputSize 
              }),
              leftIcon && "pl-10",
              rightIcon && "pr-10",
              "!bg-white",
              className
            )}
            ref={ref}
            aria-invalid={error}
            style={{ 
              backgroundColor: "white !important", 
              background: "white !important",
              backgroundImage: "none !important",
              backgroundClip: "padding-box !important",
              opacity: 1
            }}
            {...props}
          />
          {rightIcon && (
            <div className="pointer-events-none absolute right-md text-tactical-gray">
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
