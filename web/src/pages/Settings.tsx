import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Settings as SettingsIcon, ArrowLeft, Globe, Bell, Heart, Info, Shield } from 'lucide-react';
import { cn } from "@/lib/utils";
import { useSettings } from '@/lib/SettingsContext';
import { useToast } from "@/components/ui/use-toast";
import { Separator } from "@/components/ui/separator";
import { useDeviceCapabilities } from '@/lib/hooks/useDeviceCapabilities';

// Get package version (would normally come from package.json)
const APP_VERSION = '1.0.0';

const Settings: React.FC = () => {
  const { settings, updateSetting } = useSettings();
  const { toast } = useToast();
  const navigate = useNavigate();
  const capabilities = useDeviceCapabilities();

  // Handle geolocation toggle
  const handleGeolocationToggle = (enabled: boolean) => {
    if (enabled) {
      // Request geolocation permission
      navigator.geolocation.getCurrentPosition(
        // Success callback
        () => {
          // Store geolocation setting
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
      // User turned off geolocation
      updateSetting('geolocation', false);
    }
  };

  // Handle notifications toggle
  const handleNotificationsToggle = async (enabled: boolean) => {
    if (enabled) {
      try {
        // Request notification permission
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
          updateSetting('notifications', false);
        }
      } catch {
        toast({
          title: "Notification Error",
          description: "Your browser may not support notifications.",
          variant: "destructive",
        });
        updateSetting('notifications', false);
      }
    } else {
      // User turned off notifications
      updateSetting('notifications', false);
    }
  };

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="font-semibold text-2xl text-foreground">Settings</h1>
        <Button 
          variant="ghost" 
          onClick={() => navigate('/profile')}
          className="flex items-center gap-1"
        >
          <ArrowLeft className="size-4" />
          Back to Profile
        </Button>
      </div>

      {/* General Settings Section */}
      <Card className="transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="flex items-center font-semibold text-lg">
            <SettingsIcon className="mr-2 size-5 text-muted-foreground" />
            General Settings
          </CardTitle>
          <CardDescription>Configure application preferences and permissions.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Geolocation Setting */}
          <div className={cn(
             "flex items-center justify-between space-x-3 rounded-lg border p-4",
             "transition-colors hover:bg-muted/50",
             !capabilities.geolocation && "opacity-50"
          )}>
            <div className="space-y-0.5">
              <div className="flex items-center">
                <Globe className="mr-2 size-4 text-brass-gold" />
                <Label htmlFor="geolocation-switch" className="text-base">
                  Geolocation Tracking
                </Label>
              </div>
              <p className="text-sm text-muted-foreground">
                Allow location tracking for runs and local leaderboards.
              </p>
            </div>
            <Switch
              id="geolocation-switch"
              checked={settings.geolocation}
              onCheckedChange={handleGeolocationToggle}
              disabled={!capabilities.geolocation}
            />
          </div>

          {/* Notifications Setting */}
          <div className={cn(
             "flex items-center justify-between space-x-3 rounded-lg border p-4",
             "transition-colors hover:bg-muted/50",
             !capabilities.pushNotifications && "opacity-50"
          )}>
            <div className="space-y-0.5">
              <div className="flex items-center">
                <Bell className="mr-2 size-4 text-brass-gold" />
                <Label htmlFor="notifications-switch" className="text-base">
                  Notifications
                </Label>
              </div>
              <p className="text-sm text-muted-foreground">
                Receive reminders and updates about your workouts.
              </p>
            </div>
            <Switch
              id="notifications-switch"
              checked={settings.notifications}
              onCheckedChange={handleNotificationsToggle}
              disabled={!capabilities.pushNotifications}
            />
          </div>
        </CardContent>
      </Card>

      {/* Legal & About Section */}
      <Card className="transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="flex items-center font-semibold text-lg">
            <Info className="mr-2 size-5 text-muted-foreground" />
            About & Legal
          </CardTitle>
          <CardDescription>App information and legal documents.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <Heart className="mr-2 size-4 text-brass-gold" />
                <span className="text-sm">App Version</span>
              </div>
              <span className="font-mono text-sm text-muted-foreground">{APP_VERSION}</span>
            </div>
            
            <Separator />
            
            <div className="flex flex-col space-y-2">
              <div className="flex items-center">
                <Shield className="mr-2 size-4 text-brass-gold" />
                <span className="font-semibold text-sm">Legal Documents</span>
              </div>
              
              <div className="ml-6 space-y-2">
                <Button 
                  variant="link" 
                  className="h-auto p-0 text-sm text-brass-gold"
                  onClick={() => window.open('/terms.html', '_blank')}
                >
                  Terms of Service
                </Button>
                
                <Button 
                  variant="link" 
                  className="h-auto p-0 text-sm text-brass-gold"
                  onClick={() => window.open('/privacy.html', '_blank')}
                >
                  Privacy Policy
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
        <CardFooter className="border-t pt-4 text-center text-xs text-muted-foreground">
          © {new Date().getFullYear()} PT Champion. All rights reserved.
        </CardFooter>
      </Card>
    </div>
  );
};

export default Settings; 