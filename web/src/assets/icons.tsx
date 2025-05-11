import { 
  Camera,
  Video as CameraVideo,
  Dumbbell,
  BarChart,
  Users,
  Settings,
  User,
  LogOut,
  Medal,
  Trophy
} from 'lucide-react';

export type IconName = 
  | 'camera'
  | 'camera-video'
  | 'dumbbell'
  | 'chart'
  | 'users'
  | 'settings'
  | 'user'
  | 'logout'
  | 'medal'
  | 'trophy';

/**
 * Custom icon library mapping string names to icon components
 */
export const Icons = {
  'camera': Camera,
  'camera-video': CameraVideo,
  'dumbbell': Dumbbell,
  'chart': BarChart,
  'users': Users,
  'settings': Settings,
  'user': User,
  'logout': LogOut,
  'medal': Medal,
  'trophy': Trophy
}; 