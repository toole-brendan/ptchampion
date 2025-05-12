import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "../../lib/utils"

const buttonVariants = cva(
  "inline-flex shrink-0 select-none items-center justify-center gap-2 whitespace-nowrap rounded-button text-sm font-semibold uppercase transition-all focus-visible:ring-2 focus-visible:ring-brass-gold focus-visible:ring-opacity-50 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&_svg:not([class*='size-'])]:size-4 [&_svg]:pointer-events-none [&_svg]:shrink-0",
  {
    variants: {
      variant: {
        default: 
          "bg-brass-gold text-deep-ops shadow-small hover:-translate-y-1 hover:bg-brass-gold/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        primary: 
          "bg-brass-gold text-deep-ops shadow-small hover:-translate-y-1 hover:bg-brass-gold/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        destructive: 
          "bg-error text-white shadow-small hover:-translate-y-1 hover:opacity-90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        outline:
          "border border-brass-gold bg-transparent text-brass-gold shadow-small hover:-translate-y-1 hover:bg-brass-gold/10 hover:text-deep-ops hover:shadow-medium active:translate-y-0 active:shadow-small",
        secondary:
          "bg-army-tan text-command-black shadow-small hover:-translate-y-1 hover:bg-army-tan/80 hover:shadow-medium active:translate-y-0 active:shadow-small",
        "secondary-fill":
          "bg-army-tan text-command-black shadow-small hover:-translate-y-1 hover:bg-army-tan/80 hover:shadow-medium active:translate-y-0 active:shadow-small",
        ghost: 
          "text-brass-gold hover:bg-brass-gold/10 hover:text-deep-ops hover:shadow-small",
        link: "text-brass-gold underline-offset-4 hover:underline",
        success: 
          "bg-success text-white shadow-small hover:-translate-y-1 hover:bg-success/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        warning:
          "bg-warning text-deep-ops shadow-small hover:-translate-y-1 hover:bg-warning/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
        info:
          "bg-info text-white shadow-small hover:-translate-y-1 hover:bg-info/90 hover:shadow-medium active:translate-y-0 active:shadow-small",
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
      },
      uppercase: {
        true: "uppercase tracking-wide",
        false: "normal-case",
      }
    },
    defaultVariants: {
      variant: "default",
      size: "default",
      fullWidth: false,
      withIcon: false,
      uppercase: true,
    },
  }
)

interface ButtonProps extends React.ComponentProps<"button">,
  VariantProps<typeof buttonVariants> {
  asChild?: boolean
  fullWidth?: boolean
  withIcon?: boolean
  uppercase?: boolean
}

function Button({
  className,
  variant,
  size,
  fullWidth,
  withIcon,
  uppercase,
  asChild = false,
  ...props
}: ButtonProps) {
  const Comp = asChild ? Slot : "button"

  return (
    <Comp
      data-slot="button"
      className={cn(buttonVariants({ variant, size, fullWidth, withIcon, uppercase, className }))}
      {...props}
    />
  )
}

/**
 * Primary action button with brass-gold background and deep-ops text.
 */
function PrimaryButton(props: Omit<ButtonProps, 'variant'>) {
  return <Button variant="primary" {...props} />
}

/**
 * Secondary action button with outline style.
 */
function SecondaryButton(props: Omit<ButtonProps, 'variant'>) {
  return <Button variant="outline" {...props} />
}

/**
 * @deprecated Use SecondaryButton (outline style) instead for new designs. 
 * This maintains the old filled secondary style with army-tan background.
 */
function SecondaryFillButton(props: Omit<ButtonProps, 'variant'>) {
  return <Button variant="secondary-fill" {...props} />
}

/**
 * @deprecated Use SecondaryButton instead which now represents the outlined style.
 */
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
  SecondaryFillButton,
  OutlineButton, 
  IconButton 
}
