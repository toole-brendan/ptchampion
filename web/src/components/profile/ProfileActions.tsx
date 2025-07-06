import React from 'react';
import { Button } from "@/components/ui/button";
import { LogOut } from 'lucide-react';
import { SettingsSection } from '@/components/ui/settings-section';

interface ProfileActionsProps {
  onLogout: () => void;
  visible: boolean;
}

export const ProfileActions: React.FC<ProfileActionsProps> = ({
  onLogout,
  visible,
}) => {
  return (
    <div 
      className={`transition-all duration-300 ${
        visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
      }`}
    >
      <SettingsSection
        title="ACCOUNT ACTIONS"
        description="MANAGE YOUR ACCOUNT SESSION"
      >
        <div className="p-4 space-y-4">
          <Button
            onClick={onLogout}
            variant="outline"
            className="w-full border-error text-error hover:bg-error/10 font-semibold uppercase tracking-wider"
          >
            <LogOut className="mr-2 w-4 h-4" />
            LOG OUT
          </Button>
        </div>
      </SettingsSection>
    </div>
  );
};