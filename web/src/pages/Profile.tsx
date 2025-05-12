import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Loader2, UserCircle, LogOut, AlertTriangle } from 'lucide-react';
import { updateCurrentUser, deleteCurrentUser } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { UpdateUserRequest } from '../lib/types';
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
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

// Check if dev auth bypass is enabled
const DEV_AUTH_BYPASS = import.meta.env.DEV && import.meta.env.VITE_DEV_AUTH_BYPASS === 'true';

// Extended form data interface that includes password confirmation
interface ProfileFormData extends UpdateUserRequest {
  confirmPassword?: string;
}

const Profile: React.FC = () => {
  const { user, logout, isLoading: authLoading } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const [formData, setFormData] = useState<ProfileFormData>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDeletingAccount, setIsDeletingAccount] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [passwordsMatch, setPasswordsMatch] = useState(true);

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
        first_name: user.first_name || '',
        last_name: user.last_name || '',
        email: user.email || '',
        password: '',
        confirmPassword: ''
      });
    }
  }, [user]);

  // Check if passwords match whenever password or confirmPassword changes
  useEffect(() => {
    if (formData.password || formData.confirmPassword) {
      setPasswordsMatch(formData.password === formData.confirmPassword);
    } else {
      setPasswordsMatch(true); // If both fields are empty, they technically match
    }
  }, [formData.password, formData.confirmPassword]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    setMessage(null); // Clear message on change
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validate passwords match if attempting to change password
    if (formData.password && !passwordsMatch) {
      setMessage({ text: 'Passwords do not match', type: 'error' });
      return;
    }
    
    const changes = getChangedFields();
    if (Object.keys(changes).length === 0) {
      setMessage({ text: 'No changes to save', type: 'error' });
      return;
    }
    
    // In dev mode with auth bypass, just simulate a successful update
    if (DEV_AUTH_BYPASS) {
      setIsSubmitting(true);
      setMessage(null);
      
      // Simulate API delay
      setTimeout(() => {
        // Update the mock user with the new data
        const updatedUser = { ...user, ...changes };
        
        // Update the user in the React Query cache
        queryClient.setQueryData(['currentUser'], updatedUser);
        
        // Also update localStorage mock user for consistency
        if (user) {
          localStorage.setItem('userData', JSON.stringify(updatedUser));
        }
        
        setMessage({ text: 'Profile updated successfully (Dev Mode)', type: 'success' });
        setIsSubmitting(false);
        
        toast({
          title: "Profile Updated",
          description: "Your profile has been successfully updated (Dev Mode).",
          variant: "default",
        });
      }, 500);
      
      return;
    }
    
    setIsSubmitting(true);
    setMessage(null);
    
    try {
      const updated = await updateCurrentUser(changes);
      setMessage({ text: 'Profile updated successfully', type: 'success' });
      
      // Update the user in the React Query cache
      queryClient.setQueryData(['currentUser'], updated);
      
      // Reset password fields after successful update
      setFormData(prev => ({
        ...prev,
        password: '',
        confirmPassword: ''
      }));
      
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
    // In dev mode with auth bypass, just simulate account deletion
    if (DEV_AUTH_BYPASS) {
      setIsDeletingAccount(true);
      
      // Simulate API delay
      setTimeout(() => {
        toast({
          title: "Account Deleted",
          description: "Your account has been permanently deleted (Dev Mode).",
          variant: "default",
        });
        
        logout();
        navigate('/login');
      }, 1000);
      
      return;
    }
    
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


  
  // Compares formData with original user data to see if anything changed
  const formDataHasChanges = (): boolean => {
    if (!user) return false;
    
    return (
      formData.username !== user.username ||
      formData.first_name !== (user.first_name || '') ||
      formData.last_name !== (user.last_name || '') ||
      formData.email !== (user.email || '') ||
      Boolean(formData.password)
    );
  };
  
  // Returns only the fields that have changed compared to original user data
  const getChangedFields = (): UpdateUserRequest => {
    if (!user) return {};
    
    const changedFields: UpdateUserRequest = {};
    
    if (formData.username !== user.username) {
      changedFields.username = formData.username;
    }
    
    if (formData.first_name !== (user.first_name || '')) {
      changedFields.first_name = formData.first_name;
    }
    
    if (formData.last_name !== (user.last_name || '')) {
      changedFields.last_name = formData.last_name;
    }
    
    if (formData.email !== (user.email || '')) {
      changedFields.email = formData.email;
    }
    
    if (formData.password && passwordsMatch) {
      changedFields.password = formData.password;
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

  // If no user data and we're not bypassing auth, show the login prompt
  if (!user && !DEV_AUTH_BYPASS) {
    return (
      <div className="mx-auto max-w-3xl space-y-6"> {/* Consistent layout */}
        <h1 className="font-semibold text-2xl text-foreground">Profile</h1>
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
      <h1 className="font-semibold text-2xl text-foreground">Profile</h1>

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
              <Label htmlFor="first_name">First Name</Label>
              <Input 
                id="first_name" name="first_name"
                value={formData.first_name || ''} onChange={handleChange} 
                placeholder="Your first name"
                disabled={isSubmitting}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="last_name">Last Name</Label>
              <Input 
                id="last_name" name="last_name"
                value={formData.last_name || ''} onChange={handleChange} 
                placeholder="Your last name"
                disabled={isSubmitting}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="username">Username</Label>
              <Input 
                id="username" name="username"
                value={formData.username || ''} onChange={handleChange} 
                placeholder="Your unique username"
                disabled={isSubmitting} required
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="email">Email</Label>
              <Input 
                id="email" name="email"
                type="email"
                value={formData.email || ''} onChange={handleChange} 
                placeholder="Your email address"
                disabled={isSubmitting}
              />
            </div>
            
            {/* Password fields section */}
            <div className="space-y-4 rounded-md border p-4">
              <div className="text-sm font-medium">Password Management</div>
              <div className="space-y-1.5">
                <Label htmlFor="password">New Password</Label>
                <Input 
                  id="password" name="password"
                  type="password"
                  value={formData.password || ''} onChange={handleChange} 
                  placeholder="Leave blank to keep current password"
                  disabled={isSubmitting}
                  className={!passwordsMatch && Boolean(formData.password) ? "border-destructive" : ""}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="confirmPassword">Confirm New Password</Label>
                <Input 
                  id="confirmPassword" name="confirmPassword"
                  type="password"
                  value={formData.confirmPassword || ''} onChange={handleChange} 
                  placeholder="Confirm your new password"
                  disabled={isSubmitting}
                  className={!passwordsMatch && Boolean(formData.confirmPassword) ? "border-destructive" : ""}
                />
                {!passwordsMatch && Boolean(formData.password) && (
                  <p className="mt-1 text-xs text-destructive">Passwords do not match</p>
                )}
              </div>
            </div>
          </CardContent>
          <CardFooter className="border-t pt-4"> {/* Adjusted padding */}
            <Button 
              type="submit" 
              disabled={isSubmitting || !formDataHasChanges() || (formData.password && !passwordsMatch)}
              className="bg-brass-gold hover:bg-brass-gold/90"
            >
              {isSubmitting ? <Loader2 className="mr-2 size-4 animate-spin" /> : null}
              {isSubmitting ? 'Saving...' : 'Save Changes'}
            </Button>
          </CardFooter>
        </form>
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