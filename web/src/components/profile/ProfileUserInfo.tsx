import React from 'react';
import { Button } from "@/components/ui/button";
import { TextField } from "@/components/ui/text-field";
import { Loader2 } from 'lucide-react';
import { UpdateUserRequest } from '@/lib/types';
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

import { CheckCircle, AlertCircle } from 'lucide-react';

interface ProfileUserInfoProps {
  formData: UpdateUserRequest;
  message: { text: string; type: 'success' | 'error' } | null;
  isSubmitting: boolean;
  formDataHasChanges: boolean;
  handleChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  handleSubmit: (e: React.FormEvent) => void;
  setFormData: React.Dispatch<React.SetStateAction<UpdateUserRequest>>;
  visible: boolean;
}

export const ProfileUserInfo: React.FC<ProfileUserInfoProps> = ({
  formData,
  message,
  isSubmitting,
  formDataHasChanges,
  handleChange,
  handleSubmit,
  setFormData,
  visible,
}) => {
  return (
    <div 
      className={`transition-all duration-300 ${
        visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
      }`}
    >
      <SettingsSection
        title="EDIT PROFILE"
        description="UPDATE YOUR PERSONAL INFORMATION"
      >
        <form onSubmit={handleSubmit} className="p-4 space-y-6">
          {/* Status message */}
          {message && (
            <StatusAlert 
              message={message.text} 
              type={message.type}
            />
          )}
          
          {/* Form fields */}
          <div className="space-y-4">
            <TextField
              label="FIRST NAME"
              name="first_name"
              value={formData.first_name || ''}
              onChange={handleChange}
              placeholder="Your first name"
              fullWidth
              disabled={isSubmitting}
            />
            
            <TextField
              label="LAST NAME"
              name="last_name"
              value={formData.last_name || ''}
              onChange={handleChange}
              placeholder="Your last name"
              fullWidth
              disabled={isSubmitting}
            />
            
            <TextField
              label="USERNAME"
              name="username"
              value={formData.username || ''}
              onChange={handleChange}
              placeholder="Your unique username"
              fullWidth
              disabled={isSubmitting}
              required
            />
            
            <TextField
              label="EMAIL"
              name="email"
              type="email"
              value={formData.email || ''}
              onChange={handleChange}
              placeholder="Your email address"
              fullWidth
              disabled={isSubmitting}
            />
            
            {/* Gender field */}
            <div className="space-y-1">
              <label className="block text-xs font-medium uppercase tracking-wider text-command-black">
                GENDER (FOR USMC PFT SCORING)
              </label>
              <select
                name="gender"
                value={formData.gender || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, gender: e.target.value }))}
                disabled={isSubmitting}
                className="w-full px-3 py-2 rounded-md border border-tactical-gray/30 focus:border-brass-gold bg-white text-command-black text-sm focus:outline-none focus:ring-2 focus:ring-brass-gold/20 disabled:opacity-50"
              >
                <option value="">Not specified</option>
                <option value="male">Male</option>
                <option value="female">Female</option>
              </select>
            </div>
            
            {/* Date of Birth field */}
            <TextField
              label="DATE OF BIRTH (FOR AGE-BASED SCORING)"
              name="date_of_birth"
              type="date"
              value={formData.date_of_birth || ''}
              onChange={handleChange}
              placeholder=""
              fullWidth
              disabled={isSubmitting}
              max={new Date().toISOString().split('T')[0]}
            />
          </div>
          
          {/* Save button */}
          <Button
            type="submit"
            disabled={isSubmitting || !formDataHasChanges}
            className={cn(
              "w-full bg-deep-ops text-brass-gold hover:bg-deep-ops/90",
              "font-semibold uppercase tracking-wider",
              (!isSubmitting && formDataHasChanges) ? "opacity-100" : "opacity-60"
            )}
          >
            {isSubmitting && <Loader2 className="mr-2 w-4 h-4 animate-spin" />}
            {isSubmitting ? 'SAVING...' : 'SAVE CHANGES'}
          </Button>
        </form>
      </SettingsSection>
    </div>
  );
};