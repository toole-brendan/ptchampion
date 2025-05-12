import React from 'react';
import { cn } from '@/lib/utils';

type CornerDecorProps = {
  alwaysVisible?: boolean;
  className?: string;
  cornerSize?: number;
  cornerColor?: string;
  lineColor?: string;
}

/**
 * CornerDecor - Adds military-style corner cutouts and diagonal lines to UI elements
 * Can be used with cards, panels, and other containers to add the brass & cream design aesthetic
 */
export function CornerDecor({
  alwaysVisible = false,
  className = '',
  cornerSize = 10,
  cornerColor = 'var(--color-background)',
  lineColor = 'var(--color-brass-gold)'
}: CornerDecorProps) {
  return (
    <div className={cn("pointer-events-none absolute inset-0", className)}>
      {/* Corner cutouts - top left and right */}
      <div className="absolute left-0 top-0" style={{ width: cornerSize, height: cornerSize, background: cornerColor }}></div>
      <div className="absolute right-0 top-0" style={{ width: cornerSize, height: cornerSize, background: cornerColor }}></div>
      
      {/* Corner cutouts - bottom left and right */}
      <div className="absolute bottom-0 left-0" style={{ width: cornerSize, height: cornerSize, background: cornerColor }}></div>
      <div className="absolute bottom-0 right-0" style={{ width: cornerSize, height: cornerSize, background: cornerColor }}></div>
      
      {/* Diagonal lines for corners */}
      <div 
        className={`absolute left-0 top-0 h-px origin-top-left rotate-45 opacity-25 ${!alwaysVisible ? 'hidden group-hover:block' : ''}`}
        style={{ width: cornerSize, background: lineColor }}
      ></div>
      <div 
        className={`absolute right-0 top-0 h-px origin-top-right -rotate-45 opacity-25 ${!alwaysVisible ? 'hidden group-hover:block' : ''}`} 
        style={{ width: cornerSize, background: lineColor }}
      ></div>
      <div 
        className={`absolute bottom-0 left-0 h-px origin-bottom-left -rotate-45 opacity-25 ${!alwaysVisible ? 'hidden group-hover:block' : ''}`}
        style={{ width: cornerSize, background: lineColor }}
      ></div>
      <div 
        className={`absolute bottom-0 right-0 h-px origin-bottom-right rotate-45 opacity-25 ${!alwaysVisible ? 'hidden group-hover:block' : ''}`}
        style={{ width: cornerSize, background: lineColor }}
      ></div>
    </div>
  );
} 