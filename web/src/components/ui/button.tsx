import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "../../lib/utils"

const buttonVariants = cva(
  "focus-visible:ring-brass-gold focus-visible:ring-opacity-50 inline-flex shrink-0 select-none items-center justify-center gap-2 whitespace-nowrap rounded-button text-sm font-medium uppercase transition-all focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&_svg:not([class*='size-'])]:size-4 [&_svg]:pointer-events-none [&_svg]:shrink-0",
  {
    variants: {
      variant: {
        default: 
          "hover:bg-brass-gold hover:bg-opacity-90 bg-brass-gold text-cream shadow-small hover:-translate-y-1 hover:shadow-medium active:translate-y-0 active:shadow-small",
        destructive: 
          "bg-error text-white hover:opacity-90 shadow-small hover:-translate-y-1 hover:shadow-medium active:translate-y-0 active:shadow-small",
        outline:
          "hover:bg-brass-gold hover:bg-opacity-10 border border-brass-gold bg-transparent text-brass-gold shadow-small hover:-translate-y-1 hover:shadow-medium active:translate-y-0 active:shadow-small",
        secondary:
          "hover:bg-army-tan/80 bg-army-tan text-command-black shadow-small hover:-translate-y-1 hover:shadow-medium active:translate-y-0 active:shadow-small",
        ghost: 
          "hover:bg-brass-gold hover:bg-opacity-10 text-brass-gold hover:shadow-small",
        link: "text-brass-gold underline-offset-4 hover:underline",
        success: 
          "hover:bg-success/90 bg-success text-white shadow-small hover:-translate-y-1 hover:shadow-medium active:translate-y-0 active:shadow-small",
        warning:
          "hover:bg-warning/90 bg-warning text-deep-ops shadow-small hover:-translate-y-1 hover:shadow-medium active:translate-y-0 active:shadow-small",
        info:
          "hover:bg-info/90 bg-info text-white shadow-small hover:-translate-y-1 hover:shadow-medium active:translate-y-0 active:shadow-small",
      },
      size: {
        default: "h-10 px-md py-sm font-semibold text-sm",
        sm: "h-8 rounded-button px-sm py-xs font-semibold text-xs",
        lg: "h-12 rounded-button px-lg py-md font-semibold text-base",
        icon: "size-10",
      },
      fullWidth: {
        true: "w-full",
      },
      withIcon: {
        true: "inline-flex items-center gap-2",
      }
    },
    defaultVariants: {
      variant: "default",
      size: "default",
      fullWidth: false,
      withIcon: false,
    },
  }
)

interface ButtonProps extends React.ComponentProps<"button">,
  VariantProps<typeof buttonVariants> {
  asChild?: boolean
  fullWidth?: boolean
  withIcon?: boolean
}

function Button({
  className,
  variant,
  size,
  fullWidth,
  withIcon,
  asChild = false,
  ...props
}: ButtonProps) {
  const Comp = asChild ? Slot : "button"

  return (
    <Comp
      data-slot="button"
      className={cn(buttonVariants({ variant, size, fullWidth, withIcon, className }))}
      {...props}
    />
  )
}

// Export the iOS-styled buttons for quick use
function PrimaryButton(props: Omit<ButtonProps, 'variant'>) {
  return <Button variant="default" {...props} />
}

function SecondaryButton(props: Omit<ButtonProps, 'variant'>) {
  return <Button variant="secondary" {...props} />
}

function OutlineButton(props: Omit<ButtonProps, 'variant'>) {
  return <Button variant="outline" {...props} />
}

function IconButton({ 
  children, 
  size = "icon", 
  ...props 
}: Omit<ButtonProps, 'withIcon'>) {
  return (
    <Button size={size} withIcon {...props}>
      {children}
    </Button>
  )
}

export { 
  Button, 
  buttonVariants, 
  PrimaryButton, 
  SecondaryButton, 
  OutlineButton, 
  IconButton 
}
