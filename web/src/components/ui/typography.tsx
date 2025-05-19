import React from "react";
import { cn } from "@/lib/utils";

interface TextProps extends React.HTMLAttributes<HTMLParagraphElement> {
  variant?: "body" | "small" | "tiny" | "caption";
  weight?: "regular" | "semibold" | "bold";
  as?: React.ElementType;
  className?: string;
  children: React.ReactNode;
}

export function Text({
  variant = "body",
  weight = "regular",
  as: Component = "p",
  className,
  children,
  ...props
}: TextProps) {
  return (
    <Component
      className={cn(
        // Base styles
        "text-foreground",
        // Size variants
        variant === "body" && "text-body",
        variant === "small" && "text-small",
        variant === "tiny" && "text-tiny",
        variant === "caption" && "text-tiny text-text-secondary",
        // Weight variants
        weight === "regular" && "font-sans",
        weight === "semibold" && "font-semibold",
        weight === "bold" && "font-bold",
        className
      )}
      {...props}
    >
      {children}
    </Component>
  );
}

interface HeadingProps extends React.HTMLAttributes<HTMLHeadingElement> {
  level?: 1 | 2 | 3 | 4;
  as?: "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "div";
  className?: string;
  children: React.ReactNode;
}

export function Heading({
  level = 1,
  as,
  className,
  children,
  ...props
}: HeadingProps) {
  const Component = as || `h${level}` as React.ElementType;

  return (
    <Component
      className={cn(
        // Base styles
        "font-heading font-bold tracking-wide text-command-black",
        // Size variants based on level
        level === 1 && "text-heading1",
        level === 2 && "text-heading2",
        level === 3 && "text-heading3",
        level === 4 && "text-heading4",
        className
      )}
      {...props}
    >
      {children}
    </Component>
  );
}

interface LabelTextProps extends React.HTMLAttributes<HTMLSpanElement> {
  className?: string;
  children: React.ReactNode;
}

export function LabelText({ className, children, ...props }: LabelTextProps) {
  return (
    <span
      className={cn(
        "font-sans text-small font-semibold uppercase tracking-wide text-tactical-gray",
        className
      )}
      {...props}
    >
      {children}
    </span>
  );
}

interface MonoTextProps extends React.HTMLAttributes<HTMLSpanElement> {
  className?: string;
  children: React.ReactNode;
}

export function MonoText({ className, children, ...props }: MonoTextProps) {
  return (
    <span
      className={cn(
        "font-mono text-body text-command-black",
        className
      )}
      {...props}
    >
      {children}
    </span>
  );
}

// StatNumber for metrics displays
export function StatNumber({ className, children, ...props }: MonoTextProps) {
  return (
    <span
      className={cn(
        "font-mono text-heading4 font-medium text-command-black",
        className
      )}
      {...props}
    >
      {children}
    </span>
  );
} 