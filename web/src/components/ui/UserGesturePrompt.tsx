/**
 * UserGesturePrompt.tsx
 * 
 * A component that displays a prompt for the user to tap/interact
 * to resume video playback on iOS Safari, which requires a user gesture.
 */

import React from 'react';
import { usePoseContext } from '../../lib/contexts/PoseContext';
import { Button } from './button';

interface UserGesturePromptProps {
  message?: string;
  className?: string;
}

const UserGesturePrompt: React.FC<UserGesturePromptProps> = ({
  message = 'Tap to enable camera',
  className = '',
}) => {
  const { needsUserGesture, resumeCamera } = usePoseContext();

  if (!needsUserGesture) {
    return null;
  }

  return (
    <div className={`flex flex-col items-center justify-center rounded-lg bg-black/80 p-4 text-white ${className}`}>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="mb-2"
      >
        <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"></path>
        <circle cx="12" cy="13" r="4"></circle>
      </svg>
      <p className="mb-3 text-sm">{message}</p>
      <Button
        onClick={resumeCamera}
        className="bg-primary hover:bg-primary/90"
        size="sm"
      >
        Enable Camera
      </Button>
    </div>
  );
};

export default UserGesturePrompt; 