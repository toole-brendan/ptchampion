import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Loader2, UserCircle, Settings, LogOut, AlertTriangle } from 'lucide-react';
import { updateCurrentUser, deleteCurrentUser } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { UpdateUserRequest } from '../lib/types';
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { cn } from "@/lib/utils";
import { useSettings } from '@/lib/SettingsContext';
import { useToast } from "@/components/ui/use-toast";
import { 
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

const Profile: React.FC = () => {
  const { user, logout, isLoading: authLoading } = useAuth();
  const { settings, updateSetting } = useSettings();
  const { toast } = useToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const [formData, setFormData] = useState<UpdateUserRequest>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDeletingAccount, setIsDeletingAccount] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Message auto-dismiss timer
  useEffect(() => {
    if (message) {
      const timer = setTimeout(() => {
        setMessage(null);
      }, 5000); // 5 seconds
      
      return () => clearTimeout(timer);
    }
  }, [message]);

  // Initialize form with user data when it's available
  useEffect(() => {
    if (user) {
      setFormData({
        username: user.username,
        display_name: user.display_name || '',
        profile_picture_url: user.profile_picture_url || '',
        location: user.location || '',
      });
    }
  }, [user]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    setMessage(null); // Clear message on change
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const changes = getChangedFields();
    if (Object.keys(changes).length === 0) {
      setMessage({ text: 'No changes to save', type: 'error' });
      return;
    }
    
    setIsSubmitting(true);
    setMessage(null);
    
    try {
      const updated = await updateCurrentUser(changes);
      setMessage({ text: 'Profile updated successfully', type: 'success' });
      
      // Update the user in the React Query cache
      queryClient.setQueryData(['currentUser'], updated);
      
      toast({
        title: "Profile Updated",
        description: "Your profile has been successfully updated.",
        variant: "default",
      });
    } catch (error) {
      setMessage({ text: error instanceof Error ? error.message : 'Failed to update profile', type: 'error' });
      toast({
        title: "Update Failed",
        description: error instanceof Error ? error.message : 'Failed to update profile',
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteAccount = async () => {
    setIsDeletingAccount(true);
    try {
      await deleteCurrentUser();
      toast({
        title: "Account Deleted",
        description: "Your account has been permanently deleted.",
        variant: "default",
      });
      logout();
      navigate('/login');
    } catch (error) {
      toast({
        title: "Deletion Failed",
        description: error instanceof Error ? error.message : 'Failed to delete account',
        variant: "destructive",
      });
      setIsDeletingAccount(false);
    }
  };

  // Handle geolocation toggle
  const handleGeolocationToggle = (enabled: boolean) => {
    if (enabled) {
      // Request geolocation permission
      navigator.geolocation.getCurrentPosition(
        // Success callback
        (position) => {
          // Store geolocation setting
          updateSetting('geolocation', true);
          toast({
            title: "Location Access Granted",
            description: "Location services are now enabled for tracking.",
            variant: "default",
          });
        },
        // Error callback
        (error) => {
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
      } catch (error) {
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
  
  // Compares formData with original user data to see if anything changed
  const formDataHasChanges = (): boolean => {
    if (!user) return false;
    
    return (
      formData.username !== user.username ||
      formData.display_name !== (user.display_name || '') ||
      formData.profile_picture_url !== (user.profile_picture_url || '') ||
      formData.location !== (user.location || '')
    );
  };
  
  // Returns only the fields that have changed compared to original user data
  const getChangedFields = (): UpdateUserRequest => {
    if (!user) return {};
    
    const changedFields: UpdateUserRequest = {};
    
    if (formData.username !== user.username) {
      changedFields.username = formData.username;
    }
    
    if (formData.display_name !== (user.display_name || '')) {
      changedFields.display_name = formData.display_name;
    }
    
    if (formData.profile_picture_url !== (user.profile_picture_url || '')) {
      changedFields.profile_picture_url = formData.profile_picture_url;
    }
    
    if (formData.location !== (user.location || '')) {
      changedFields.location = formData.location;
    }
    
    return changedFields;
  };

  if (authLoading) {
    return (
      <div className="mx-auto max-w-3xl animate-pulse space-y-6"> {/* Consistent spacing */}
        <div className="h-8 w-1/2 rounded bg-muted"></div> {/* Header placeholder */}
        {[1, 2, 3].map((i) => ( // Card placeholders
          <div key={i} className="space-y-4 rounded-lg bg-muted p-6">
            <div className="h-6 w-1/3 rounded bg-muted-foreground/20"></div>
            <div className="h-4 w-2/3 rounded bg-muted-foreground/10"></div>
            <div className="space-y-2 pt-2">
              <div className="h-4 w-1/4 rounded bg-muted-foreground/10"></div>
              <div className="h-10 rounded bg-muted-foreground/20"></div>
            </div>
            <div className="space-y-2 pt-2">
              <div className="h-4 w-1/4 rounded bg-muted-foreground/10"></div>
              <div className="h-10 rounded bg-muted-foreground/20"></div>
            </div>
             <div className="border-border/50 border-t pt-4">
               <div className="h-10 w-1/4 rounded bg-muted-foreground/20"></div>
             </div>
          </div>
        ))}
      </div>
    );
  }

  if (!user) {
    return (
      <div className="mx-auto max-w-3xl space-y-6"> {/* Consistent layout */}
        <h1 className="font-semibold text-2xl text-foreground">Profile & Settings</h1>
        <Card>
          <CardContent className="pt-6 text-center text-muted-foreground">
             Please log in to view and edit your profile.
             <Button onClick={() => navigate('/login')} className="mt-4">
               Login
             </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-3xl space-y-6"> {/* Reduced space, kept max-width */}
      <h1 className="font-semibold text-2xl text-foreground">Profile & Settings</h1>

      {/* Edit Profile Section */}
      <Card className="transition-shadow hover:shadow-md"> {/* Hover effect */}
        <CardHeader>
          <CardTitle className="flex items-center font-semibold text-lg"> {/* Standardized */}
              <UserCircle className="mr-2 size-5 text-muted-foreground" /> {/* Muted icon */}
              Edit Profile
          </CardTitle>
          <CardDescription>Update your personal information.</CardDescription>
        </CardHeader>
        <form onSubmit={handleSubmit}>
          <CardContent className="space-y-4">
            {/* Message Display */}
             {message && (
               <Alert variant={message.type === 'error' ? 'destructive' : 'default'} className="transition-opacity duration-300">
                 <AlertTitle>{message.type === 'success' ? 'Success' : 'Error'}</AlertTitle>
                 <AlertDescription>{message.text}</AlertDescription>
               </Alert>
             )}
            
            <div className="space-y-1.5"> {/* Reduced space */}
              <Label htmlFor="username">Username</Label>
              <Input 
                id="username" name="username" // Added name attribute
                value={formData.username || ''} onChange={handleChange} 
                placeholder="Your unique username"
                disabled={isSubmitting} required // Add required
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="display_name">Display Name</Label>
              <Input 
                id="display_name" name="display_name" // Added name attribute
                value={formData.display_name || ''} onChange={handleChange} 
                placeholder="How your name appears"
                disabled={isSubmitting}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="profile_picture_url">Profile Picture URL</Label>
              <Input 
                id="profile_picture_url" name="profile_picture_url" // Added name attribute
                type="url" // Use URL type
                value={formData.profile_picture_url || ''} onChange={handleChange} 
                placeholder="https://... (optional)"
                disabled={isSubmitting}
              />
              {formData.profile_picture_url && (
                <img 
                  src={formData.profile_picture_url} alt="Preview" 
                  className="border-border mt-2 size-16 rounded-full border object-cover" // Adjusted size/style
                  onError={(e) => { e.currentTarget.style.display = 'none'; }} // Hide on error
                />
              )}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="location">Location</Label>
              <Input 
                id="location" name="location" // Added name attribute
                value={formData.location || ''} onChange={handleChange} 
                placeholder="City, Country (optional)"
                disabled={isSubmitting}
              />
            </div>
          </CardContent>
          <CardFooter className="border-t pt-4"> {/* Adjusted padding */}
            <Button 
              type="submit" 
              disabled={isSubmitting || !formDataHasChanges()}
              className="bg-brass-gold hover:bg-brass-gold/90"
            >
              {isSubmitting ? <Loader2 className="mr-2 size-4 animate-spin" /> : null}
              {isSubmitting ? 'Saving...' : 'Save Changes'}
            </Button>
          </CardFooter>
        </form>
      </Card>

      {/* Settings Section */}
      <Card className="transition-shadow hover:shadow-md"> {/* Hover effect */}
        <CardHeader>
          <CardTitle className="flex items-center font-semibold text-lg"> {/* Standardized */}
              <Settings className="mr-2 size-5 text-muted-foreground" /> {/* Muted icon */}
              App Settings
          </CardTitle>
          <CardDescription>Configure application preferences.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Geolocation Setting */}
          <div className={cn(
             "flex items-center justify-between space-x-3 rounded-lg border p-4", // Use standard border/padding
             "transition-colors hover:bg-muted/50" // Hover effect
          )}>
            <div className="space-y-0.5">
              <Label htmlFor="geolocation-switch" className="text-base"> {/* Slightly larger label */}
                Geolocation Tracking
              </Label>
              <p className="text-sm text-muted-foreground">
                Allow location tracking for runs and local leaderboards.
              </p>
            </div>
            <Switch
              id="geolocation-switch"
              checked={settings.geolocation}
              onCheckedChange={handleGeolocationToggle}
            />
          </div>

          {/* Notifications Setting */}
          <div className={cn(
             "flex items-center justify-between space-x-3 rounded-lg border p-4",
             "transition-colors hover:bg-muted/50"
          )}>
            <div className="space-y-0.5">
              <Label htmlFor="notifications-switch" className="text-base">
                Notifications
              </Label>
              <p className="text-sm text-muted-foreground">
                Receive reminders and updates about your workouts.
              </p>
            </div>
            <Switch
              id="notifications-switch"
              checked={settings.notifications}
              onCheckedChange={handleNotificationsToggle}
            />
          </div>
          
          {/* Link to Settings page for more options */}
          <div className="pt-2 text-center">
            <Button 
              variant="outline" 
              onClick={() => navigate('/settings')}
              className="w-full"
            >
              <Settings className="mr-2 size-4" />
              More Settings
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Account Actions Section */}
      <Card className="border-destructive/50 transition-shadow hover:shadow-md"> {/* Destructive border hint */}
        <CardHeader>
          <CardTitle className="flex items-center font-semibold text-lg text-destructive"> {/* Destructive color */}
              Account Actions
          </CardTitle>
          <CardDescription>Manage your account.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
            <Button variant="destructive" onClick={logout} className="w-full sm:w-auto"> {/* Use context logout */}
              <LogOut className="mr-2 size-4" /> Logout
            </Button>
            
            {/* Delete Account button with confirmation dialog */}
            <Dialog>
              <DialogTrigger asChild>
                <Button variant="outline" className="ml-0 w-full border-destructive text-destructive hover:bg-destructive/10 sm:ml-2 sm:w-auto">
                  <AlertTriangle className="mr-2 size-4" /> Delete Account
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Delete Your Account?</DialogTitle>
                  <DialogDescription>
                    This will permanently remove your account and all associated data. This action cannot be undone.
                  </DialogDescription>
                </DialogHeader>
                <DialogFooter>
                  <DialogClose asChild>
                    <Button variant="outline">Cancel</Button>
                  </DialogClose>
                  <Button 
                    onClick={handleDeleteAccount}
                    className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                    disabled={isDeletingAccount}
                  >
                    {isDeletingAccount && <Loader2 className="mr-2 size-4 animate-spin" />}
                    {isDeletingAccount ? 'Deleting...' : 'Delete Account'}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
        </CardContent>
      </Card>
    </div>
  );
};

export default Profile; 