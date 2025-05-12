import { cn } from "@/lib/utils";

interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className }: SkeletonProps) {
  return (
    <div
      className={cn("animate-pulse rounded bg-army-tan/30", className)}
    />
  );
}

interface SkeletonRowProps {
  cols?: number;
  className?: string;
}

export function SkeletonRow({ cols = 3, className }: SkeletonRowProps) {
  return (
    <tr className={cn("border-b border-olive-mist/10", className)}>
      {Array.from({ length: cols }).map((_, i) => (
        <td key={i} className="p-2">
          <div className="h-4 w-full rounded bg-army-tan/20 animate-pulse" />
        </td>
      ))}
    </tr>
  );
} 