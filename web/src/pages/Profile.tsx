import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch"; // Added Switch import
import { Loader2, UserCircle, Settings, LogOut } from 'lucide-react'; // Removed MapPin, added more icons
import { updateCurrentUser } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { UpdateUserRequest } from '../lib/types'; // Removed UserResponse
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"; // Import Alert
import { cn } from "@/lib/utils"; // Import cn

const Profile: React.FC = () => {
  const { user, logout, loading: authLoading } = useAuth();
  
  const [formData, setFormData] = useState<UpdateUserRequest>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

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
      await updateCurrentUser(changes);
      setMessage({ text: 'Profile updated successfully', type: 'success' });
      // Consider updating the user context here if needed, depends on useAuth implementation
    } catch (error) {
      setMessage({ text: error instanceof Error ? error.message : 'Failed to update profile', type: 'error' });
    } finally {
      setIsSubmitting(false);
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
      <div className="space-y-6 max-w-3xl mx-auto animate-pulse"> {/* Consistent spacing */}
        <div className="h-8 bg-muted rounded w-1/2"></div> {/* Header placeholder */}
        {[1, 2, 3].map((i) => ( // Card placeholders
          <div key={i} className="bg-muted rounded-lg p-6 space-y-4">
            <div className="h-6 bg-muted-foreground/20 rounded w-1/3"></div>
            <div className="h-4 bg-muted-foreground/10 rounded w-2/3"></div>
            <div className="space-y-2 pt-2">
              <div className="h-4 bg-muted-foreground/10 rounded w-1/4"></div>
              <div className="h-10 bg-muted-foreground/20 rounded"></div>
            </div>
            <div className="space-y-2 pt-2">
              <div className="h-4 bg-muted-foreground/10 rounded w-1/4"></div>
              <div className="h-10 bg-muted-foreground/20 rounded"></div>
            </div>
             <div className="border-t border-border/50 pt-4">
               <div className="h-10 bg-muted-foreground/20 rounded w-1/4"></div>
             </div>
          </div>
        ))}
      </div>
    );
  }

  if (!user) {
    return (
      <div className="space-y-6 max-w-3xl mx-auto"> {/* Consistent layout */}
        <h1 className="text-2xl font-semibold text-foreground">Profile & Settings</h1>
        <Card>
          <CardContent className="pt-6 text-center text-muted-foreground">
             Please log in to view and edit your profile.
             {/* Maybe add a login button/link here */}
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-3xl mx-auto"> {/* Reduced space, kept max-width */}
      <h1 className="text-2xl font-semibold text-foreground">Profile & Settings</h1>

      {/* Edit Profile Section */}
      <Card className="transition-shadow hover:shadow-md"> {/* Hover effect */}
        <CardHeader>
          <CardTitle className="text-lg font-semibold flex items-center"> {/* Standardized */}
              <UserCircle className="h-5 w-5 mr-2 text-muted-foreground" /> {/* Muted icon */}
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
                  className="mt-2 h-16 w-16 rounded-full object-cover border border-border" // Adjusted size/style
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
            <Button type="submit" disabled={isSubmitting || !formDataHasChanges()}>
              {isSubmitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              {isSubmitting ? 'Saving...' : 'Save Changes'}
            </Button>
          </CardFooter>
        </form>
      </Card>

      {/* Settings Section (Simplified Example) */}
      <Card className="transition-shadow hover:shadow-md"> {/* Hover effect */}
        <CardHeader>
          <CardTitle className="text-lg font-semibold flex items-center"> {/* Standardized */}
              <Settings className="h-5 w-5 mr-2 text-muted-foreground" /> {/* Muted icon */}
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
              // Add state and handler here based on actual implementation
              // checked={geolocationEnabled} 
              // onCheckedChange={setGeolocationEnabled}
            />
          </div>
          {/* Placeholder for more settings */}
           <p className="text-sm text-muted-foreground text-center pt-2">
             More settings coming soon.
           </p>
        </CardContent>
         {/* Remove footer if no save action needed for settings yet */}
         {/* <CardFooter className="border-t pt-4">
           <Button disabled>Save Settings</Button>
         </CardFooter> */}
      </Card>

      {/* Account Actions Section */}
      <Card className="border-destructive/50 transition-shadow hover:shadow-md"> {/* Destructive border hint */}
        <CardHeader>
          <CardTitle className="text-lg font-semibold text-destructive flex items-center"> {/* Destructive color */}
              Account Actions
          </CardTitle>
          <CardDescription>Manage your account.</CardDescription>
        </CardHeader>
        <CardContent>
            <Button variant="destructive" onClick={logout} className="w-full sm:w-auto"> {/* Use context logout */}
              <LogOut className="mr-2 h-4 w-4" /> Logout
            </Button>
            {/* Add Delete Account button here later if needed */}
        </CardContent>
      </Card>
    </div>
  );
};

export default Profile; 