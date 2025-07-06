import React from 'react';
import { Button } from "@/components/ui/button";
import { TextField } from "@/components/ui/text-field";
import { Loader2, CheckCircle, AlertCircle } from 'lucide-react';
import { SettingsSection } from '@/components/ui/settings-section';
import { cn } from "@/lib/utils";

interface StatusAlertProps {
  message: string;
  type: 'success' | 'error';
  className?: string;
}

const StatusAlert: React.FC<StatusAlertProps> = ({ message, type, className }) => (
  <div className={cn(
    "flex items-center p-4 rounded-lg",
    type === 'success' 
      ? "bg-success/10 border border-success/20" 
      : "bg-error/10 border border-error/20",
    className
  )}>
    {type === 'success' ? (
      <CheckCircle className="w-5 h-5 text-success mr-3 flex-shrink-0" />
    ) : (
      <AlertCircle className="w-5 h-5 text-error mr-3 flex-shrink-0" />
    )}
    <p className={cn(
      "text-sm font-medium",
      type === 'success' ? "text-success" : "text-error"
    )}>
      {message}
    </p>
  </div>
);

interface ProfilePasswordProps {
  passwordData: { password: string; confirmPassword: string };
  passwordMessage: { text: string; type: 'success' | 'error' } | null;
  isChangingPassword: boolean;
  passwordsMatch: boolean;
  handlePasswordChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  handlePasswordSubmit: (e: React.FormEvent) => void;
  visible: boolean;
}

export const ProfilePassword: React.FC<ProfilePasswordProps> = ({
  passwordData,
  passwordMessage,
  isChangingPassword,
  passwordsMatch,
  handlePasswordChange,
  handlePasswordSubmit,
  visible,
}) => {
  return (
    <div 
      className={`transition-all duration-300 ${
        visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
      }`}
    >
      <SettingsSection
        title="PASSWORD MANAGEMENT"
        description="UPDATE YOUR PASSWORD REGULARLY FOR SECURITY"
      >
        <form onSubmit={handlePasswordSubmit} className="p-4 space-y-6">
          {/* Password status message */}
          {passwordMessage && (
            <StatusAlert 
              message={passwordMessage.text} 
              type={passwordMessage.type}
            />
          )}
          
          {/* Password fields */}
          <div className="space-y-4">
            <TextField
              label="NEW PASSWORD"
              name="password"
              type="password"
              value={passwordData.password}
              onChange={handlePasswordChange}
              placeholder="Enter new password"
              fullWidth
              disabled={isChangingPassword}
              error={!passwordsMatch && Boolean(passwordData.password)}
            />
            
            <TextField
              label="CONFIRM PASSWORD"
              name="confirmPassword"
              type="password"
              value={passwordData.confirmPassword}
              onChange={handlePasswordChange}
              placeholder="Confirm new password"
              fullWidth
              disabled={isChangingPassword}
              error={!passwordsMatch && Boolean(passwordData.confirmPassword)}
              errorMessage={!passwordsMatch && Boolean(passwordData.password) ? "Passwords do not match" : undefined}
            />
          </div>
          
          {/* Change Password button */}
          <Button
            type="submit"
            disabled={isChangingPassword || !passwordData.password || !passwordsMatch}
            className={cn(
              "w-full bg-deep-ops text-brass-gold hover:bg-deep-ops/90",
              "font-semibold uppercase tracking-wider",
              (passwordData.password && passwordsMatch && !isChangingPassword) ? "opacity-100" : "opacity-60"
            )}
          >
            {isChangingPassword && <Loader2 className="mr-2 w-4 h-4 animate-spin" />}
            {isChangingPassword ? 'UPDATING...' : 'CHANGE PASSWORD'}
          </Button>
        </form>
      </SettingsSection>
    </div>
  );
};