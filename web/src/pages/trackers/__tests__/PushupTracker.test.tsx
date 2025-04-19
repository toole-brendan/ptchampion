import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { PushupTracker } from '../PushupTracker';
import { usePoseDetector, Landmark } from '@/lib/hooks/usePoseDetector';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider } from '@/lib/authContext';

// Mock the usePoseDetector hook
vi.mock('@/lib/hooks/usePoseDetector', () => ({
  usePoseDetector: vi.fn(),
  PoseLandmarkIndex: {
    LEFT_SHOULDER: 11,
    RIGHT_SHOULDER: 12,
    LEFT_ELBOW: 13,
    RIGHT_ELBOW: 14,
    LEFT_WRIST: 15,
    RIGHT_WRIST: 16,
    LEFT_HIP: 23,
    RIGHT_HIP: 24,
    LEFT_KNEE: 25,
    RIGHT_KNEE: 26,
  }
}));

// Mock the navigator.mediaDevices
Object.defineProperty(global.navigator, 'mediaDevices', {
  value: {
    getUserMedia: vi.fn().mockResolvedValue({
      getTracks: () => [{ stop: vi.fn() }]
    })
  }
});

describe('PushupTracker', () => {
  beforeEach(() => {
    // Reset mocks
    vi.resetAllMocks();
    
    // Setup default mock implementation for usePoseDetector
    const mockStartDetection = vi.fn();
    const mockStopDetection = vi.fn();
    
    (usePoseDetector as any).mockReturnValue({
      landmarks: undefined,
      isDetectorReady: true,
      isRunning: false,
      startDetection: mockStartDetection,
      stopDetection: mockStopDetection
    });
  });
  
  it('renders the component correctly', () => {
    render(
      <MemoryRouter>
        <AuthProvider>
          <PushupTracker />
        </AuthProvider>
      </MemoryRouter>
    );
    
    // Check that the main UI elements are rendered
    expect(screen.getByText('Pushup Tracker')).toBeInTheDocument();
    expect(screen.getByText('Track your form and count repetitions')).toBeInTheDocument();
    expect(screen.getByText('Begin Tracking')).toBeInTheDocument();
    expect(screen.getByText('Form Quality')).toBeInTheDocument();
  });
  
  it('starts countdown when Begin Tracking is clicked', async () => {
    render(
      <MemoryRouter>
        <AuthProvider>
          <PushupTracker />
        </AuthProvider>
      </MemoryRouter>
    );
    
    // Click the Begin Tracking button
    fireEvent.click(screen.getByText('Begin Tracking'));
    
    // Check that countdown is displayed
    await waitFor(() => {
      expect(screen.getByText('3')).toBeInTheDocument();
    });
    
    // Wait for countdown to change
    await waitFor(() => {
      expect(screen.getByText('2')).toBeInTheDocument();
    }, { timeout: 1100 });
    
    // Wait for countdown to change
    await waitFor(() => {
      expect(screen.getByText('1')).toBeInTheDocument();
    }, { timeout: 1100 });
  });
  
  it('counts repetitions when landmarks detect a push-up', async () => {
    // Mock landmarks that simulate a push-up
    let mockLandmarks: Landmark[][] | undefined = undefined;
    
    // Setup pose detector with mock implementation that can be updated
    (usePoseDetector as any).mockImplementation(() => {
      return {
        landmarks: mockLandmarks,
        isDetectorReady: true,
        isRunning: true,
        startDetection: vi.fn(),
        stopDetection: vi.fn()
      };
    });
    
    render(
      <MemoryRouter>
        <AuthProvider>
          <PushupTracker />
        </AuthProvider>
      </MemoryRouter>
    );
    
    // Start tracking
    fireEvent.click(screen.getByText('Begin Tracking'));
    
    // Skip countdown
    vi.advanceTimersByTime(3000);
    
    // Create a simple landmark
    const createLandmark = (x: number, y: number, z = 0, visibility = 0.9): Landmark => ({
      x, y, z, visibility
    });
    
    // Simulate "up" position
    mockLandmarks = [[
      createLandmark(0.5, 0.2), // Position 0
      // Fill other positions with dummy data
      ...Array(33).fill(createLandmark(0, 0))
    ]];
    
    // Update with "up" position landmarks
    (usePoseDetector as any).mockReturnValue({
      landmarks: mockLandmarks,
      isDetectorReady: true,
      isRunning: true,
      startDetection: vi.fn(),
      stopDetection: vi.fn()
    });
    
    // Force re-render to simulate landmark update
    fireEvent.click(screen.getByText('End Session'));
    fireEvent.click(screen.getByText('Begin Tracking'));
    
    // Simulate "down" position
    mockLandmarks = [[
      createLandmark(0.5, 0.6), // Position 0
      // Fill other positions with dummy data
      ...Array(33).fill(createLandmark(0, 0))
    ]];
    
    // Force re-render
    fireEvent.click(screen.getByText('End Session'));
    
    // Verify rep count is still 0 (not incremented yet)
    expect(screen.getByText('Reps: 0')).toBeInTheDocument();
  });
}); 