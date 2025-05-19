import { useEffect } from "react";
import { ToastProps, useToast } from "./use-toast";

interface ToastItemProps {
  toast: ToastProps;
  onDismiss: (id: string) => void;
}

/**
 * Individual toast component
 */
const ToastItem = ({ toast, onDismiss }: ToastItemProps) => {
  // Auto-dismiss after duration
  useEffect(() => {
    if (toast.duration) {
      const timer = setTimeout(() => {
        onDismiss(toast.id);
        if (toast.onClose) toast.onClose();
      }, toast.duration);
      
      return () => clearTimeout(timer);
    }
  }, [toast, onDismiss]);

  // Get appropriate classes based on variant
  const getBgClass = () => {
    switch (toast.variant) {
      case "destructive":
        return "bg-red-100 border-red-500 text-red-800";
      case "success":
        return "bg-green-100 border-green-500 text-green-800";
      default:
        return "bg-white border-gray-300 text-gray-800";
    }
  };

  return (
    <div
      className={`mb-3 rounded-lg border p-4 shadow-md ${getBgClass()} animate-slide-in`}
      role="alert"
    >
      <div className="flex items-center justify-between">
        <div className="mr-3 font-semibold">{toast.title}</div>
        <button 
          onClick={() => {
            onDismiss(toast.id);
            if (toast.onClose) toast.onClose();
          }}
          className="font-bold"
        >
          &times;
        </button>
      </div>
      
      {toast.description && (
        <div className="mt-1 text-sm">{toast.description}</div>
      )}
    </div>
  );
};

/**
 * Container component for all toasts
 */
export function Toaster() {
  const { toasts, dismiss } = useToast();

  if (toasts.length === 0) return null;

  return (
    <div className="fixed right-0 top-4 z-50 max-w-xs px-4">
      {toasts.map((toast) => (
        <ToastItem key={toast.id} toast={toast} onDismiss={dismiss} />
      ))}
    </div>
  );
} 