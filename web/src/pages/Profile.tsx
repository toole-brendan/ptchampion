import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { Button } from "@/components/ui/button";
import { TextField } from "@/components/ui/text-field";
import { Loader2, UserCircle, LogOut, Settings, CheckCircle, AlertCircle } from 'lucide-react';
import { updateCurrentUser } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { UpdateUserRequest } from '../lib/types';
import { useToast } from "@/components/ui/use-toast";
import { cn } from "@/lib/utils";
import useStaggeredAnimation from '@/hooks/useStaggeredAnimation';
import { MilitarySettingsHeader } from '@/components/ui/military-settings-header';
import { SettingsSection } from '@/components/ui/settings-section';

// Check if dev auth bypass is enabled
const DEV_AUTH_BYPASS = import.meta.env.DEV && import.meta.env.VITE_DEV_AUTH_BYPASS === 'true';

// Extended form data interface that includes password confirmation
interface ProfileFormData extends UpdateUserRequest {
  confirmPassword?: string;
}

// Status Alert Component
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

// Toast Notification Component
interface ToastNotificationProps {
  message: string;
  visible: boolean;
}

const ToastNotification: React.FC<ToastNotificationProps> = ({ message, visible }) => (
  <div className={cn(
    "fixed bottom-6 left-1/2 transform -translate-x-1/2 z-50",
    "bg-success text-white px-6 py-3 rounded-lg shadow-lg",
    "flex items-center space-x-2 transition-all duration-300",
    visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4 pointer-events-none"
  )}>
    <CheckCircle className="w-5 h-5" />
    <span className="font-medium">{message}</span>
  </div>
);

const Profile: React.FC = () => {
  const { user, logout, isLoading: authLoading } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const [formData, setFormData] = useState<ProfileFormData>({});
  const [passwordData, setPasswordData] = useState<{password: string, confirmPassword: string}>({
    password: '',
    confirmPassword: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isChangingPassword, setIsChangingPassword] = useState(false);

  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [passwordMessage, setPasswordMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [passwordsMatch, setPasswordsMatch] = useState(true);
  
  // Animation states
  const [headerVisible, setHeaderVisible] = useState(false);
  const [sectionsVisible, setSectionsVisible] = useState([false, false, false]);
  
  // Toast states
  const [showSuccessToast, setShowSuccessToast] = useState(false);
  const [showPasswordSuccessToast, setShowPasswordSuccessToast] = useState(false);
  const [toastMessage, setToastMessage] = useState('');

  // Staggered animation for sections
  const visibleSections = useStaggeredAnimation({
    itemCount: 3, // Edit Profile, Password Management, Account Actions
    baseDelay: 200,
    staggerDelay: 100
  });

  // Message auto-dismiss timer
  useEffect(() => {
    if (message) {
      const timer = setTimeout(() => {
        setMessage(null);
      }, 5000);
      
      return () => clearTimeout(timer);
    }
  }, [message]);

  // Password message auto-dismiss timer
  useEffect(() => {
    if (passwordMessage) {
      const timer = setTimeout(() => {
        setPasswordMessage(null);
      }, 5000);
      
      return () => clearTimeout(timer);
    }
  }, [passwordMessage]);

  // Initialize form with user data when it's available
  useEffect(() => {
    if (user) {
      setFormData({
        username: user.username,
        first_name: user.first_name || '',
        last_name: user.last_name || '',
        email: user.email || ''
      });
    }
  }, [user]);

  // Check if passwords match whenever password or confirmPassword changes
  useEffect(() => {
    if (passwordData.password || passwordData.confirmPassword) {
      setPasswordsMatch(passwordData.password === passwordData.confirmPassword);
    } else {
      setPasswordsMatch(true);
    }
  }, [passwordData.password, passwordData.confirmPassword]);

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

  // Toast auto-dismiss
  useEffect(() => {
    if (showSuccessToast) {
      const timer = setTimeout(() => setShowSuccessToast(false), 3000);
      return () => clearTimeout(timer);
    }
  }, [showSuccessToast]);

  useEffect(() => {
    if (showPasswordSuccessToast) {
      const timer = setTimeout(() => setShowPasswordSuccessToast(false), 3000);
      return () => clearTimeout(timer);
    }
  }, [showPasswordSuccessToast]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    setMessage(null);
  };

  const handlePasswordChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setPasswordData(prev => ({ ...prev, [name]: value }));
    setPasswordMessage(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const changes = getChangedFields();
    if (Object.keys(changes).length === 0) {
      setMessage({ text: 'No changes to save', type: 'error' });
      return;
    }
    
    if (DEV_AUTH_BYPASS) {
      setIsSubmitting(true);
      setMessage(null);
      
      setTimeout(() => {
        const updatedUser = { ...user, ...changes };
        queryClient.setQueryData(['currentUser'], updatedUser);
        
        if (user) {
          localStorage.setItem('userData', JSON.stringify(updatedUser));
        }
        
        setMessage({ text: 'Profile updated successfully', type: 'success' });
        setIsSubmitting(false);
        
        // Show toast
        setToastMessage('Profile updated successfully');
        setShowSuccessToast(true);
        
        toast({
          title: "Profile Updated",
          description: "Your profile has been successfully updated.",
          variant: "default",
        });
      }, 1000);
      
      return;
    }
    
    setIsSubmitting(true);
    setMessage(null);
    
    try {
      const updated = await updateCurrentUser(changes);
      setMessage({ text: 'Profile updated successfully', type: 'success' });
      
      queryClient.setQueryData(['currentUser'], updated);
      
      // Show toast
      setToastMessage('Profile updated successfully');
      setShowSuccessToast(true);
      
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
  
  const handlePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!passwordData.password) {
      setPasswordMessage({ text: 'Please enter a new password', type: 'error' });
      return;
    }
    
    if (!passwordsMatch) {
      setPasswordMessage({ text: 'Passwords do not match', type: 'error' });
      return;
    }
    
    if (DEV_AUTH_BYPASS) {
      setIsChangingPassword(true);
      setPasswordMessage(null);
      
      setTimeout(() => {
        setPasswordMessage({ text: 'Password updated successfully', type: 'success' });
        setIsChangingPassword(false);
        
        setPasswordData({
          password: '',
          confirmPassword: ''
        });
        
        // Show toast
        setToastMessage('Password updated successfully');
        setShowPasswordSuccessToast(true);
        
        toast({
          title: "Password Updated",
          description: "Your password has been successfully updated.",
          variant: "default",
        });
      }, 1000);
      
      return;
    }
    
    setIsChangingPassword(true);
    setPasswordMessage(null);
    
    try {
      const changes: UpdateUserRequest = {
        password: passwordData.password
      };
      
      const updated = await updateCurrentUser(changes);
      setPasswordMessage({ text: 'Password updated successfully', type: 'success' });
      
      queryClient.setQueryData(['currentUser'], updated);
      
      setPasswordData({
        password: '',
        confirmPassword: ''
      });
      
      // Show toast
      setToastMessage('Password updated successfully');
      setShowPasswordSuccessToast(true);
      
      toast({
        title: "Password Updated",
        description: "Your password has been successfully updated.",
        variant: "default",
      });
    } catch (error) {
      setPasswordMessage({ text: error instanceof Error ? error.message : 'Failed to update password', type: 'error' });
      toast({
        title: "Password Update Failed",
        description: error instanceof Error ? error.message : 'Failed to update password',
        variant: "destructive",
      });
    } finally {
      setIsChangingPassword(false);
    }
  };

  const formDataHasChanges = (): boolean => {
    if (!user) return false;
    
    return (
      formData.username !== user.username ||
      formData.first_name !== (user.first_name || '') ||
      formData.last_name !== (user.last_name || '') ||
      formData.email !== (user.email || '')
    );
  };
  
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
    
    return changedFields;
  };

  if (authLoading) {
    return (
      <div className="min-h-screen bg-gradient-radial from-cream/90 to-cream">
        <div className="max-w-3xl mx-auto px-4">
          <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
            <div className="text-center">
              <Loader2 className="mx-auto mb-4 size-10 animate-spin text-brass-gold"/>
              <p className="font-heading text-lg uppercase tracking-wider text-deep-ops">Loading profile...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!user && !DEV_AUTH_BYPASS) {
    return (
      <div className="min-h-screen bg-gradient-radial from-cream/90 to-cream">
        <div className="max-w-3xl mx-auto px-4">
          <SettingsSection
            title="PROFILE"
            description="PLEASE LOG IN TO VIEW AND EDIT YOUR PROFILE"
          >
            <div className="text-center py-8">
              <Button 
                onClick={() => navigate('/login')} 
                className="bg-brass-gold text-deep-ops hover:bg-brass-gold/90"
              >
                LOGIN
              </Button>
            </div>
          </SettingsSection>
        </div>
      </div>
    );
  }

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
            title="PROFILE"
            description="MANAGE YOUR ACCOUNT"
            onBack={() => navigate('/settings')}
          />
        </div>

        <div className="space-y-6 pb-8">
          {/* Edit Profile Section */}
          <div 
            className={`transition-all duration-300 ${
              sectionsVisible[0] ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
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
                </div>
                
                {/* Save button */}
                <Button
                  type="submit"
                  disabled={isSubmitting || !formDataHasChanges()}
                  className={cn(
                    "w-full bg-deep-ops text-brass-gold hover:bg-deep-ops/90",
                    "font-semibold uppercase tracking-wider",
                    (!isSubmitting && formDataHasChanges()) ? "opacity-100" : "opacity-60"
                  )}
                >
                  {isSubmitting && <Loader2 className="mr-2 w-4 h-4 animate-spin" />}
                  {isSubmitting ? 'SAVING...' : 'SAVE CHANGES'}
                </Button>
              </form>
            </SettingsSection>
          </div>

          {/* Password Management Section */}
          <div 
            className={`transition-all duration-300 ${
              sectionsVisible[1] ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
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

          {/* Account Actions Section */}
          <div 
            className={`transition-all duration-300 ${
              sectionsVisible[2] ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
            }`}
          >
            <SettingsSection
              title="ACCOUNT ACTIONS"
              description="MANAGE YOUR ACCOUNT SESSION"
            >
              <div className="p-4 space-y-4">
                <Button
                  onClick={() => {
                    logout();
                    navigate('/login');
                  }}
                  variant="outline"
                  className="w-full border-error text-error hover:bg-error/10 font-semibold uppercase tracking-wider"
                >
                  <LogOut className="mr-2 w-4 h-4" />
                  LOG OUT
                </Button>
              </div>
            </SettingsSection>
          </div>
        </div>
      </div>

      {/* Toast Notifications */}
      <ToastNotification 
        message={toastMessage}
        visible={showSuccessToast || showPasswordSuccessToast}
      />
    </div>
  );
};

export default Profile; 