import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, expect, test } from 'vitest';
import { BrowserRouter } from 'react-router-dom';
import WorkoutCard from '../WorkoutCard';
import { ExerciseResponse } from '@/lib/types';

// Mock exercise data
const mockPushupWorkout: ExerciseResponse = {
  id: 123,
  user_id: 1,
  exercise_id: 1,
  exercise_type: 'Push-ups',
  exercise_name: 'Push-ups',
  reps: 30,
  time_in_seconds: 120,
  grade: 85,
  created_at: '2023-07-15T14:30:00Z',
};

const mockRunWorkout: ExerciseResponse = {
  id: 456,
  user_id: 1,
  exercise_id: 4,
  exercise_type: 'Running',
  exercise_name: 'Running',
  distance: 5000, // 5km in meters
  time_in_seconds: 1800, // 30 minutes
  grade: 92,
  created_at: '2023-07-16T08:15:00Z',
};

// Wrapper to provide router context for Link component
const renderWithRouter = (ui: React.ReactElement) => {
  return render(ui, { wrapper: BrowserRouter });
};

describe('WorkoutCard Component', () => {
  test('renders pushup workout correctly', () => {
    renderWithRouter(<WorkoutCard workout={mockPushupWorkout} />);
    
    // Check exercise type is displayed
    expect(screen.getByText('Push-ups')).toBeInTheDocument();
    
    // Check date is displayed
    expect(screen.getByText((content) => content.includes('Jul 15, 2023'))).toBeInTheDocument();
    
    // Check reps are displayed
    expect(screen.getByText('30')).toBeInTheDocument();
    
    // Check duration is displayed
    expect(screen.getByText((content) => content.includes('2:00'))).toBeInTheDocument();
    
    // Check grade is displayed
    expect(screen.getByText('85%')).toBeInTheDocument();
    
    // Verify the link points to the correct URL
    const linkElement = screen.getByRole('link');
    expect(linkElement).toHaveAttribute('href', '/history/123');
  });
  
  test('renders running workout correctly', () => {
    renderWithRouter(<WorkoutCard workout={mockRunWorkout} />);
    
    // Check exercise type is displayed
    expect(screen.getByText('Running')).toBeInTheDocument();
    
    // Check date is displayed
    expect(screen.getByText((content) => content.includes('Jul 16, 2023'))).toBeInTheDocument();
    
    // Check distance is displayed and formatted correctly (5.00 km)
    expect(screen.getByText('5.00 km')).toBeInTheDocument();
    
    // Check duration is displayed
    expect(screen.getByText((content) => content.includes('30:00'))).toBeInTheDocument();
    
    // Check grade is displayed
    expect(screen.getByText('92%')).toBeInTheDocument();
    
    // Verify the link points to the correct URL
    const linkElement = screen.getByRole('link');
    expect(linkElement).toHaveAttribute('href', '/history/456');
  });
}); 