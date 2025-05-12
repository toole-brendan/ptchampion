import React, { forwardRef, useEffect, useId, useRef, useState } from 'react';
import { X } from 'lucide-react';
import { Button } from './button';
import { cn } from '@/lib/utils';

export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: React.ReactNode;
  description?: React.ReactNode;
  children: React.ReactNode;
  actions?: React.ReactNode;
  className?: string;
  contentClassName?: string;
  showCloseButton?: boolean;
}

export const Modal = forwardRef<HTMLDivElement, ModalProps>(({
  isOpen,
  onClose,
  title,
  description,
  children,
  actions,
  className,
  contentClassName,
  showCloseButton = true,
}, ref) => {
  const [isClosing, setIsClosing] = useState(false);
  const dialogRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);
  
  const titleId = useId();
  const descriptionId = useId();

  // Handle closing animation
  const handleClose = () => {
    setIsClosing(true);
    setTimeout(() => {
      setIsClosing(false);
      onClose();
    }, 200);
  };

  // Close on escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        handleClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen]);

  // Lock body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      // Save current focus
      previousFocusRef.current = document.activeElement as HTMLElement;
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  // Focus management
  useEffect(() => {
    if (isOpen && dialogRef.current) {
      // Set focus to first focusable element or dialog itself
      const focusableElements = dialogRef.current.querySelectorAll<HTMLElement>(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      
      if (focusableElements.length > 0) {
        focusableElements[0].focus();
      } else {
        dialogRef.current.focus();
      }
    } else if (!isOpen && previousFocusRef.current) {
      // Restore focus when closed
      previousFocusRef.current.focus();
    }
  }, [isOpen]);

  if (!isOpen && !isClosing) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div 
        className={cn(
          "fixed inset-0 bg-deep-ops/50 backdrop-blur-sm transition-opacity duration-200",
          isClosing ? "opacity-0" : "opacity-100"
        )}
        onClick={handleClose}
        aria-hidden="true"
      />

      {/* Modal content */}
      <div 
        ref={ref || dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={title ? titleId : undefined}
        aria-describedby={description ? descriptionId : undefined}
        tabIndex={-1}
        className={cn(
          "w-11/12 max-w-lg bg-cream rounded-card shadow-card p-6 relative",
          "transition-all duration-200 overflow-y-auto max-h-[80vh]",
          isClosing ? "scale-95 opacity-0" : "scale-100 opacity-100",
          className
        )}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close button (top-right) */}
        {showCloseButton && (
          <Button
            variant="ghost"
            size="icon"
            onClick={handleClose}
            className="absolute right-4 top-4 text-command-black hover:bg-tactical-gray/10"
          >
            <X className="size-5" />
            <span className="sr-only">Close</span>
          </Button>
        )}

        {/* Header */}
        {title && (
          <h2 
            id={titleId}
            className="font-heading text-heading3 text-command-black mb-2"
          >
            {title}
          </h2>
        )}
        
        {description && (
          <p 
            id={descriptionId}
            className="text-sm text-tactical-gray mb-4"
          >
            {description}
          </p>
        )}

        {/* Content */}
        <div className={cn(contentClassName)}>
          {children}
        </div>

        {/* Footer */}
        {actions && (
          <div className="mt-6 flex justify-end space-x-3">
            {actions}
          </div>
        )}
      </div>
    </div>
  );
});

Modal.displayName = 'Modal';

interface ModalHeaderProps {
  children: React.ReactNode;
  className?: string;
}

export function ModalHeader({ children, className }: ModalHeaderProps) {
  return (
    <div className={cn("mb-4", className)}>
      {children}
    </div>
  );
}

interface ModalFooterProps {
  children: React.ReactNode;
  className?: string;
}

export function ModalFooter({ children, className }: ModalFooterProps) {
  return (
    <div className={cn("mt-6 flex justify-end space-x-3", className)}>
      {children}
    </div>
  );
} 