import { useToast } from "./use-toast";
import { Toaster } from "./toaster";
import { useEffect } from "react";

/**
 * Toast provider component that initializes the global toast API
 */
export function ToastProvider({ children }: { children: React.ReactNode }) {
  const { toast } = useToast();

  // Expose the toast function globally
  useEffect(() => {
    if (typeof window !== "undefined") {
      window.showToast = ({ title, description, duration, variant }) => {
        toast({
          title,
          description,
          duration: duration || 3000,
          variant: variant || "default",
        });
      };
    }

    return () => {
      // Clean up when component unmounts
      if (typeof window !== "undefined") {
        // @ts-expect-error - We're explicitly removing the property
        window.showToast = undefined;
      }
    };
  }, [toast]);

  return (
    <>
      {children}
      <Toaster />
    </>
  );
} 