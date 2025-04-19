import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "../../lib/utils"

const buttonVariants = cva(
  "inline-flex shrink-0 items-center justify-center gap-2 whitespace-nowrap rounded-lg text-sm font-medium uppercase outline-none transition-all focus-visible:ring-2 focus-visible:ring-brass-gold/50 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&_svg:not([class*='size-'])]:size-4 [&_svg]:pointer-events-none [&_svg]:shrink-0",
  {
    variants: {
      variant: {
        default:
          "bg-brass-gold text-white shadow-sm shadow-black/20 text-shadow hover:bg-brass-gold/90 hover:underline",
        destructive:
          "bg-red-600 text-white shadow-sm hover:bg-red-700",
        outline:
          "border border-brass-gold bg-transparent text-brass-gold shadow-sm hover:bg-brass-gold/10",
        secondary:
          "bg-army-tan text-command-black shadow-sm hover:bg-army-tan/80",
        ghost:
          "text-brass-gold hover:bg-brass-gold/10",
        link: "text-brass-gold underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-5 py-2 text-sm font-bold",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-12 rounded-lg px-6 text-base",
        icon: "size-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

function Button({
  className,
  variant,
  size,
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean
  }) {
  const Comp = asChild ? Slot : "button"

  return (
    <Comp
      data-slot="button"
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  )
}

export { Button, buttonVariants }
