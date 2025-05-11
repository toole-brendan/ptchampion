import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "../../lib/utils"

const buttonVariants = cva(
  "inline-flex shrink-0 items-center justify-center gap-2 whitespace-nowrap rounded-button text-sm font-medium uppercase transition-all focus-visible:ring-2 focus-visible:ring-brass-gold/50 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&_svg:not([class*='size-'])]:size-4 [&_svg]:pointer-events-none [&_svg]:shrink-0 select-none",
  {
    variants: {
      variant: {
        default:
          "bg-brass-gold text-cream shadow-small hover:-translate-y-1 hover:bg-brass-gold/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        destructive:
          "bg-error text-white shadow-small hover:-translate-y-1 hover:bg-error/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        outline:
          "border border-brass-gold bg-transparent text-brass-gold shadow-small hover:-translate-y-1 hover:bg-brass-gold/10 hover:shadow-medium active:translate-y-0 active:shadow-small",
        secondary:
          "bg-army-tan text-command-black shadow-small hover:-translate-y-1 hover:bg-army-tan/80 hover:shadow-medium active:translate-y-0 active:shadow-small",
        ghost:
          "text-brass-gold hover:bg-brass-gold/10 hover:shadow-small",
        link: "text-brass-gold underline-offset-4 hover:underline",
        success: 
          "bg-success text-white shadow-small hover:-translate-y-1 hover:bg-success/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        warning:
          "bg-warning text-deep-ops shadow-small hover:-translate-y-1 hover:bg-warning/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        info:
          "bg-info text-white shadow-small hover:-translate-y-1 hover:bg-info/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
      },
      size: {
        default: "h-10 px-md py-sm text-sm font-semibold",
        sm: "h-8 rounded-button px-sm py-xs text-xs font-semibold",
        lg: "h-12 rounded-button px-lg py-md text-base font-semibold",
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
