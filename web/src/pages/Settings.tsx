import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Globe, Bell, Heart, Radio, ExternalLink, Trash2 } from 'lucide-react';
import { useSettings } from '@/lib/SettingsContext';
import { useToast } from "@/components/ui/use-toast";
import { useDeviceCapabilities } from '@/lib/hooks/useDeviceCapabilities';
import { MilitarySettingsHeader } from '@/components/ui/military-settings-header';
import { SettingsSection } from '@/components/ui/settings-section';
import { SettingsToggleRow, SettingsActionRow, SettingsDivider } from '@/components/ui/settings-row';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';

// Get package version (would normally come from package.json)
const APP_VERSION = '1.0.0';

const Settings: React.FC = () => {
  const { settings, updateSetting, isUpdating } = useSettings();
  const { toast } = useToast();
  const navigate = useNavigate();
  const capabilities = useDeviceCapabilities();

  // Animation states
  const [headerVisible, setHeaderVisible] = useState(false);
  const [sectionsVisible, setSectionsVisible] = useState([false, false, false, false]);
  
  // Dialog states
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
  const [isDeletingAccount, setIsDeletingAccount] = useState(false);

  // Handle geolocation toggle
  const handleGeolocationToggle = (enabled: boolean) => {
    if (enabled) {
      // Request geolocation permission
      navigator.geolocation.getCurrentPosition(
        // Success callback
        () => {
          updateSetting('geolocation', true);
          toast({
            title: "Location Access Granted",
            description: "Location services are now enabled for tracking.",
            variant: "default",
          });
        },
        // Error callback
        () => {
          toast({
            title: "Location Access Denied",
            description: "Please enable location access in your browser settings.",
            variant: "destructive",
          });
          updateSetting('geolocation', false);
        }
      );
    } else {
      updateSetting('geolocation', false);
    }
  };

  // Handle notifications toggle
  const handleNotificationsToggle = async (enabled: boolean) => {
    if (enabled) {
      try {
        const permission = await Notification.requestPermission();
        if (permission === 'granted') {
          updateSetting('notifications', true);
          toast({
            title: "Notifications Enabled",
            description: "You will now receive workout reminders and updates.",
            variant: "default",
          });
        } else {
          toast({
            title: "Notification Permission Denied",
            description: "Please enable notifications in your browser settings.",
            variant: "destructive",
          });
          await updateSetting('notifications', false);
        }
      } catch {
        toast({
          title: "Notification Error",
          description: "Your browser may not support notifications.",
          variant: "destructive",
        });
        await updateSetting('notifications', false);
      }
    } else {
      await updateSetting('notifications', false);
    }
  };

  // Handle device management
  const handleDeviceManagement = () => {
    toast({
      title: "Feature Coming Soon",
      description: "Fitness device management will be available in a future update.",
      variant: "default",
    });
  };

  // Handle account deletion
  const handleDeleteAccount = async () => {
    setIsDeletingAccount(true);
    
    // Simulate API call
    setTimeout(() => {
      toast({
        title: "Account Deleted",
        description: "Your account has been permanently deleted.",
        variant: "destructive",
      });
      setIsDeletingAccount(false);
      setShowDeleteConfirmation(false);
      // In a real app, this would redirect to login
      navigate('/login');
    }, 2000);
  };

  // Animate content in on mount
  useEffect(() => {
    const timer1 = setTimeout(() => {
      setHeaderVisible(true);
    }, 100);

    const sectionTimers = sectionsVisible.map((_, index) => 
      setTimeout(() => {
        setSectionsVisible(prev => {
          const newState = [...prev];
          newState[index] = true;
          return newState;
        });
      }, 200 + (index * 100))
    );

    return () => {
      clearTimeout(timer1);
      sectionTimers.forEach(clearTimeout);
    };
  }, []);

  return (
    <div className="min-h-screen bg-gradient-radial from-cream/90 to-cream">
      <div className="max-w-3xl mx-auto px-4">
        {/* Military Header */}
        <div 
          className={`transition-all duration-300 ${
            headerVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2'
          }`}
        >
          <MilitarySettingsHeader
            title="SETTINGS"
            description="CONFIGURE YOUR PREFERENCES"
            onBack={() => navigate('/profile')}
          />
        </div>

        <div className="space-y-6 pb-8">
          {/* General Settings Section */}
          <div 
            className={`transition-all duration-300 ${
              sectionsVisible[0] ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
            }`}
          >
            <SettingsSection
              title="GENERAL SETTINGS"
              description="CONFIGURE APPLICATION PREFERENCES"
            >
              <SettingsToggleRow
                icon={<Globe className="w-5 h-5" />}
                title="GEOLOCATION TRACKING"
                description="Allow location tracking for runs and local leaderboards"
                checked={settings.geolocation}
                onCheckedChange={handleGeolocationToggle}
                disabled={!capabilities.geolocation || isUpdating}
              />
              
              <SettingsDivider />
              
              <SettingsToggleRow
                icon={<Bell className="w-5 h-5" />}
                title="NOTIFICATIONS"
                description="Receive reminders and updates about your workouts"
                checked={settings.notifications}
                onCheckedChange={handleNotificationsToggle}
                disabled={!capabilities.pushNotifications || isUpdating}
              />
            </SettingsSection>
          </div>

          {/* Fitness Devices Section */}
          <div 
            className={`transition-all duration-300 ${
              sectionsVisible[1] ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
            }`}
          >
            <SettingsSection
              title="FITNESS DEVICES"
              description="CONNECT FITNESS TRACKING DEVICES"
            >
              <SettingsActionRow
                icon={<Radio className="w-5 h-5" />}
                title="MANAGE DEVICES"
                description="Connect watches and heart rate monitors"
                onClick={handleDeviceManagement}
              />
            </SettingsSection>
          </div>

          {/* Legal & About Section */}
          <div 
            className={`transition-all duration-300 ${
              sectionsVisible[2] ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
            }`}
          >
            <SettingsSection
              title="ABOUT & LEGAL"
              description="APP INFORMATION AND LEGAL DOCUMENTS"
            >
              <SettingsActionRow
                icon={<Heart className="w-5 h-5" />}
                title="APP VERSION"
                description=""
                value={APP_VERSION}
                onClick={() => {}}
              />
              
              <SettingsDivider />
              
              <SettingsActionRow
                icon={<ExternalLink className="w-4 h-4" />}
                title="TERMS OF SERVICE"
                description=""
                onClick={() => window.open('/terms.html', '_blank')}
              />
              
              <SettingsDivider />
              
              <SettingsActionRow
                icon={<ExternalLink className="w-4 h-4" />}
                title="PRIVACY POLICY"
                description=""
                onClick={() => window.open('/privacy.html', '_blank')}
              />
              
              {/* Copyright */}
              <div className="text-center py-4 text-xs text-tactical-gray">
                © {new Date().getFullYear()} PT Champion. All rights reserved.
              </div>
            </SettingsSection>
          </div>

          {/* Danger Zone Section */}
          <div 
            className={`transition-all duration-300 ${
              sectionsVisible[3] ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
            }`}
          >
            <SettingsSection
              title="DANGER ZONE"
              description="PERMANENTLY DELETE YOUR ACCOUNT"
              variant="danger"
            >
              <div className="p-4 space-y-4">
                <p className="text-sm text-tactical-gray leading-relaxed">
                  Once you delete your account, there is no going back. All your data will be permanently removed.
                </p>
                
                <Button
                  variant="destructive"
                  onClick={() => setShowDeleteConfirmation(true)}
                  disabled={isDeletingAccount}
                  className="w-full flex items-center gap-2"
                >
                  {isDeletingAccount ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      <span className="text-sm font-semibold uppercase">DELETING...</span>
                    </>
                  ) : (
                    <>
                      <Trash2 className="w-4 h-4" />
                      <span className="text-sm font-semibold uppercase">DELETE ACCOUNT</span>
                    </>
                  )}
                </Button>
              </div>
            </SettingsSection>
          </div>
        </div>
      </div>

      {/* Delete Confirmation Dialog */}
      <Dialog open={showDeleteConfirmation} onOpenChange={setShowDeleteConfirmation}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Delete</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete your account? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowDeleteConfirmation(false)}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDeleteAccount}
              disabled={isDeletingAccount}
            >
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default Settings; 