import React from 'react';
import { X } from 'lucide-react';
import { Button } from './button';
import { cn } from '@/lib/utils';
import { CornerDecor } from './corner-decor';

export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: React.ReactNode;
  description?: React.ReactNode;
  children: React.ReactNode;
  className?: string;
  contentClassName?: string;
  showCloseButton?: boolean;
  withCorners?: boolean;
}

export function Modal({
  isOpen,
  onClose,
  title,
  description,
  children,
  className,
  contentClassName,
  showCloseButton = true,
  withCorners = true,
}: ModalProps) {
  const [isClosing, setIsClosing] = React.useState(false);

  // Handle closing animation
  const handleClose = () => {
    setIsClosing(true);
    setTimeout(() => {
      setIsClosing(false);
      onClose();
    }, 200);
  };

  // Close on escape key
  React.useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        handleClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen]);

  // Lock body scroll when modal is open
  React.useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  if (!isOpen && !isClosing) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div 
        className={cn(
          "fixed inset-0 bg-deep-ops bg-opacity-50 backdrop-blur-sm transition-opacity",
          isClosing ? "opacity-0" : "opacity-100"
        )}
        onClick={handleClose}
      />

      {/* Modal content */}
      <div 
        className={cn(
          "group relative w-full max-w-lg rounded-panel bg-cream shadow-large border border-brass-gold border-opacity-20 transition-all",
          isClosing ? "scale-95 opacity-0" : "scale-100 opacity-100",
          className
        )}
        onClick={(e) => e.stopPropagation()}
      >
        {withCorners && <CornerDecor alwaysVisible />}

        {/* Header */}
        {(title || showCloseButton) && (
          <div className="section-header p-md">
            <div className="flex items-center justify-between">
              {title && (
                <h2 className="font-heading text-heading3 uppercase tracking-wide text-cream">
                  {title}
                </h2>
              )}
              {showCloseButton && (
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={handleClose}
                  className="text-cream hover:bg-deep-ops hover:bg-opacity-70"
                >
                  <X className="size-5" />
                  <span className="sr-only">Close</span>
                </Button>
              )}
            </div>
            {description && (
              <div className="mt-2 text-sm text-army-tan">
                {description}
              </div>
            )}
          </div>
        )}

        {/* Content */}
        <div className={cn("bg-cream-dark p-md", contentClassName)}>
          {children}
        </div>
      </div>
    </div>
  );
}

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
    <div className={cn("mt-6 flex justify-end gap-2", className)}>
      {children}
    </div>
  );
} 