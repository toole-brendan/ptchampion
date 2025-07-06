import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { Button } from "@/components/ui/button";
import { Loader2, UserCircle, Settings, CheckCircle } from 'lucide-react';
import { updateCurrentUser } from '../lib/apiClient';
import { useAuth } from '../lib/authContext';
import { UpdateUserRequest } from '../lib/types';
import { useToast } from "@/components/ui/use-toast";
import { cn } from "@/lib/utils";
import useStaggeredAnimation from '@/hooks/useStaggeredAnimation';
import { useOptimisticProfile } from '@/lib/hooks/useOptimisticProfile';
import { MilitarySettingsHeader } from '@/components/ui/military-settings-header';
import { SettingsSection } from '@/components/ui/settings-section';

// Import the split components
import { ProfileUserInfo } from '@/components/profile/ProfileUserInfo';
import { ProfilePassword } from '@/components/profile/ProfilePassword';
import { ProfileActions } from '@/components/profile/ProfileActions';

// Check if dev auth bypass is enabled
const DEV_AUTH_BYPASS = import.meta.env.DEV && import.meta.env.VITE_DEV_AUTH_BYPASS === 'true';

// Extended form data interface that includes password confirmation
interface ProfileFormData extends UpdateUserRequest {
  confirmPassword?: string;
}

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
  const profileMutation = useOptimisticProfile();
  
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
  const sectionsRef = useStaggeredAnimation<HTMLDivElement>(setSectionsVisible, 100);

  useEffect(() => {
    if (user) {
      setFormData({
        username: user.username || '',
        first_name: user.first_name || '',
        last_name: user.last_name || '',
        email: user.email || '',
        gender: user.gender || '',
        date_of_birth: user.date_of_birth || ''
      });
    }
  }, [user]);

  useEffect(() => {
    setHeaderVisible(true);
  }, []);

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

  useEffect(() => {
    if (passwordData.password && passwordData.confirmPassword) {
      setPasswordsMatch(passwordData.password === passwordData.confirmPassword);
    } else {
      setPasswordsMatch(true);
    }
  }, [passwordData.password, passwordData.confirmPassword]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handlePasswordChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setPasswordData(prev => ({ ...prev, [name]: value }));
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
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
    
    profileMutation.mutate(changes, {
      onSuccess: () => {
        setMessage({ text: 'Profile updated successfully', type: 'success' });
        
        // Show toast
        setToastMessage('Profile updated successfully');
        setShowSuccessToast(true);
        
        toast({
          title: "Profile Updated",
          description: "Your profile has been successfully updated.",
          variant: "default",
        });
      },
      onError: (error) => {
        setMessage({ text: error instanceof Error ? error.message : 'Failed to update profile', type: 'error' });
        toast({
          title: "Update Failed",
          description: error instanceof Error ? error.message : 'Failed to update profile',
          variant: "destructive",
        });
      },
      onSettled: () => {
        setIsSubmitting(false);
      }
    });
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
      formData.email !== (user.email || '') ||
      formData.gender !== (user.gender || '') ||
      formData.date_of_birth !== (user.date_of_birth || '')
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
    
    if (formData.gender !== (user.gender || '')) {
      changedFields.gender = formData.gender;
    }
    
    if (formData.date_of_birth !== (user.date_of_birth || '')) {
      changedFields.date_of_birth = formData.date_of_birth;
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
              <p className="text-tactical-gray font-semibold">LOADING PROFILE...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen bg-gradient-radial from-cream/90 to-cream">
        <div className="max-w-3xl mx-auto px-4">
          <SettingsSection 
            title="NOT AUTHENTICATED"
            description="PLEASE LOG IN TO MANAGE YOUR PROFILE"
          >
            <div className="p-8 flex flex-col items-center">
              <UserCircle className="mb-4 size-20 text-brass-gold" />
              <p className="mb-6 text-center text-tactical-gray">
                You need to be logged in to access your profile.
              </p>
              <Button
                onClick={() => navigate('/login')}
                className="bg-deep-ops text-brass-gold hover:bg-deep-ops/90 font-semibold uppercase tracking-wider"
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

        <div className="space-y-6 pb-8" ref={sectionsRef}>
          {/* Edit Profile Section */}
          <ProfileUserInfo
            formData={formData}
            message={message}
            isSubmitting={isSubmitting}
            formDataHasChanges={formDataHasChanges()}
            handleChange={handleChange}
            handleSubmit={handleSubmit}
            setFormData={setFormData}
            visible={sectionsVisible[0]}
          />

          {/* Password Management Section */}
          <ProfilePassword
            passwordData={passwordData}
            passwordMessage={passwordMessage}
            isChangingPassword={isChangingPassword}
            passwordsMatch={passwordsMatch}
            handlePasswordChange={handlePasswordChange}
            handlePasswordSubmit={handlePasswordSubmit}
            visible={sectionsVisible[1]}
          />

          {/* Account Actions Section */}
          <ProfileActions
            onLogout={handleLogout}
            visible={sectionsVisible[2]}
          />
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