import { useState, useCallback } from "react";

export type ToastProps = {
  id: string;
  title: string;
  description?: string;
  duration?: number;
  variant?: "default" | "destructive" | "success";
  onClose?: () => void;
};

type ToastOptions = Omit<ToastProps, "id">;

/**
 * Custom hook for managing toast notifications
 * @returns Toast functionality
 */
export function useToast() {
  const [toasts, setToasts] = useState<ToastProps[]>([]);

  const toast = useCallback((options: ToastOptions) => {
    const id = Math.random().toString(36).substring(2, 9);
    const newToast: ToastProps = {
      id,
      title: options.title,
      description: options.description,
      duration: options.duration || 3000,
      variant: options.variant || "default",
      onClose: options.onClose,
    };

    setToasts((prevToasts) => [...prevToasts, newToast]);

    return id;
  }, []);

  const dismiss = useCallback((id: string) => {
    setToasts((prevToasts) => prevToasts.filter((toast) => toast.id !== id));
  }, []);

  const dismissAll = useCallback(() => {
    setToasts([]);
  }, []);

  return {
    toast,
    dismiss,
    dismissAll,
    toasts,
  };
} 