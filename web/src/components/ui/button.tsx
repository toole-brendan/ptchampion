import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "../../lib/utils"

const buttonVariants = cva(
  "relative inline-flex shrink-0 select-none items-center justify-center gap-2 whitespace-nowrap rounded-button font-semibold transition-all duration-base focus-visible:ring-2 focus-visible:ring-brass-gold focus-visible:ring-opacity-50 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hit-target",
  {
    variants: {
      variant: {
        default: 
          "bg-brass-gold text-deep-ops shadow-button-primary hover:shadow-medium active:shadow-small",
        primary: 
          "bg-brass-gold text-deep-ops shadow-button-primary hover:shadow-medium active:shadow-small",
        secondary:
          "bg-secondary/10 text-command-black border border-tactical-gray/30 hover:border-tactical-gray/50",
        destructive: 
          "bg-error text-white shadow-small hover:shadow-medium active:shadow-small",
        outline:
          "border border-brass-gold bg-transparent text-brass-gold hover:bg-brass-gold/10",
        ghost: 
          "text-brass-gold hover:bg-brass-gold/10",
        link: "text-brass-gold underline-offset-4 hover:underline",
      },
      size: {
        small: "h-8 px-3 py-2 text-xs",
        medium: "h-10 px-4 py-3 text-sm", 
        large: "h-12 px-5 py-4 text-base",
        icon: "size-10",
      },
      fullWidth: {
        true: "w-full",
      },
      uppercase: {
        true: "uppercase tracking-wide",
        false: "normal-case",
      },
      loading: {
        true: "",
      }
    },
    defaultVariants: {
      variant: "default",
      size: "medium",
      fullWidth: false,
      uppercase: true,
      loading: false,
    },
  }
)

// Spinner component
const ButtonSpinner = ({ className }: { className?: string }) => (
  <svg
    className={cn("animate-spin", className)}
    xmlns="http://www.w3.org/2000/svg"
    fill="none"
    viewBox="0 0 24 24"
    width="1em"
    height="1em"
  >
    <circle
      className="opacity-25"
      cx="12"
      cy="12"
      r="10"
      stroke="currentColor"
      strokeWidth="4"
    />
    <path
      className="opacity-75"
      fill="currentColor"
      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
    />
  </svg>
)

interface ButtonProps extends React.ComponentProps<"button">,
  VariantProps<typeof buttonVariants> {
  asChild?: boolean
  fullWidth?: boolean
  uppercase?: boolean
  loading?: boolean
  icon?: React.ReactNode
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ 
    className,
    variant,
    size,
    fullWidth,
    uppercase,
    loading = false,
    icon,
    asChild = false,
    disabled,
    onClick,
    children,
    ...props
  }, ref) => {
    const [isPressed, setIsPressed] = React.useState(false)
    const Comp = asChild ? Slot : "button"

    // Handle press animation
    const handlePointerDown = () => {
      setIsPressed(true)
      // Haptic feedback alternative - visual pulse
      if ('vibrate' in navigator) {
        navigator.vibrate(10) // Very short vibration if supported
      }
    }

    const handlePointerUp = () => {
      setIsPressed(false)
    }

    const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
      if (loading || disabled) return
      
      // Audio feedback for button press
      try {
        const audio = new Audio()
        audio.volume = 0.1
        // Create a click sound using Web Audio API
        const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)()
        const oscillator = audioContext.createOscillator()
        const gainNode = audioContext.createGain()
        
        oscillator.connect(gainNode)
        gainNode.connect(audioContext.destination)
        
        oscillator.frequency.value = 800
        gainNode.gain.setValueAtTime(0.1, audioContext.currentTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1)
        
        oscillator.start(audioContext.currentTime)
        oscillator.stop(audioContext.currentTime + 0.1)
      } catch (error) {
        // Silently fail if audio doesn't work
      }

      onClick?.(e)
    }

    return (
      <Comp
        ref={ref}
        data-slot="button"
        className={cn(
          buttonVariants({ variant, size, fullWidth, uppercase, loading, className }),
          isPressed && "scale-[0.97] transition-transform duration-fast",
          loading && "cursor-wait"
        )}
        disabled={disabled || loading}
        onPointerDown={handlePointerDown}
        onPointerUp={handlePointerUp}
        onPointerLeave={handlePointerUp}
        onClick={handleClick}
        {...props}
      >
        <span className={cn(
          "inline-flex items-center gap-2",
          loading && "opacity-0"
        )}>
          {icon && (
            <span className="inline-flex shrink-0" style={{ fontSize: size === 'small' ? '14px' : size === 'large' ? '18px' : '16px' }}>
              {icon}
            </span>
          )}
          {children}
        </span>
        {loading && (
          <span className="absolute inset-0 flex items-center justify-center">
            <ButtonSpinner className="text-current" />
          </span>
        )}
      </Comp>
    )
  }
)

Button.displayName = "Button"

// Extended style support for backwards compatibility
type ExtendedButtonProps = Omit<ButtonProps, 'variant'> & {
  style?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive'
  variant?: ButtonProps['variant']
}

const ExtendedButton = React.forwardRef<HTMLButtonElement, ExtendedButtonProps>(
  (props, ref) => {
    const { style, variant, ...restProps } = props
    
    // Map old style prop to variant
    let mappedVariant: ButtonProps['variant'] = variant
    
    if (style) {
      const styleMap: Record<string, ButtonProps['variant']> = {
        'primary': 'primary',
        'secondary': 'secondary', 
        'outline': 'outline',
        'ghost': 'ghost',
        'destructive': 'destructive'
      }
      mappedVariant = styleMap[style]
    }

    return <Button ref={ref} variant={mappedVariant} {...restProps} />
  }
)

ExtendedButton.displayName = "ExtendedButton"

/**
 * Primary action button with brass-gold background and deep-ops text.
 */
const PrimaryButton = React.forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  (props, ref) => <Button ref={ref} variant="primary" {...props} />
)
PrimaryButton.displayName = "PrimaryButton"

/**
 * Secondary action button with subtle background.
 */
const SecondaryButton = React.forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  (props, ref) => <Button ref={ref} variant="secondary" {...props} />
)
SecondaryButton.displayName = "SecondaryButton"

/**
 * Outline button variant.
 */
const OutlineButton = React.forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  (props, ref) => <Button ref={ref} variant="outline" {...props} />
)
OutlineButton.displayName = "OutlineButton"

/**
 * Icon-only button.
 */
const IconButton = React.forwardRef<HTMLButtonElement, Omit<ButtonProps, 'size'>>(
  ({ children, ...props }, ref) => (
    <Button ref={ref} size="icon" {...props}>
      {children}
    </Button>
  )
)
IconButton.displayName = "IconButton"

export { 
  Button, 
  buttonVariants, 
  PrimaryButton, 
  SecondaryButton,
  OutlineButton, 
  IconButton,
  ExtendedButton,
  type ButtonProps
}
