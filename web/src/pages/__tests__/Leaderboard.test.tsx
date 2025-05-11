import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import Leaderboard from '../Leaderboard';

// Mock the useApi hook
vi.mock('@/lib/apiClient', () => ({
  useApi: () => ({
    leaderboard: {
      getLeaderboard: vi.fn(),
      getLocalLeaderboard: vi.fn(),
    },
  }),
}));

// Mock the Lottie Player component
vi.mock('@lottiefiles/react-lottie-player', () => ({
  Player: ({ children }: { children?: React.ReactNode }) => (
    <div data-testid="lottie-player">{children}</div>
  ),
}));

// Mock the animation import
vi.mock('@/assets/empty-leaderboard.json', () => ({}));

describe('Leaderboard Component', () => {
  // Stub geolocation API
  const mockGeolocation = {
    getCurrentPosition: vi.fn().mockImplementation((success) => {
      success({
        coords: {
          latitude: 40.7128,
          longitude: -74.0060,
        },
      });
    }),
  };

  beforeEach(() => {
    // @ts-expect-error - Mocking navigator.geolocation which is readonly
    global.navigator.geolocation = mockGeolocation;
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('renders leaderboard with default filters', async () => {
    render(<Leaderboard />);
    
    // Check if title and description are rendered
    expect(screen.getByText(/Leaderboard/i)).toBeInTheDocument();
    expect(screen.getByText(/See how you stack up against the competition/i)).toBeInTheDocument();
    
    // Check if filter controls are rendered
    expect(screen.getByText(/Exercise/i)).toBeInTheDocument();
    expect(screen.getByText(/Scope/i)).toBeInTheDocument();
    
    // Wait for the initial data to be loaded and rendered
    await waitFor(() => {
      const tableRows = screen.getAllByRole('row');
      // Header row + at least one data row
      expect(tableRows.length).toBeGreaterThan(1);
    });
  });

  it('filters leaderboard by exercise type', async () => {
    render(<Leaderboard />);
    
    // Open exercise filter dropdown
    fireEvent.click(screen.getByRole('combobox', { name: /Exercise/i }));
    
    // Wait for dropdown to open
    await waitFor(() => {
      expect(screen.getByText('Push-ups')).toBeInTheDocument();
    });
    
    // Select 'Push-ups' exercise
    fireEvent.click(screen.getByText('Push-ups'));
    
    // Verify that the filter has been applied
    await waitFor(() => {
      expect(screen.getByText(/Top Performers - Push-ups/i)).toBeInTheDocument();
    });
  });

  it('switches to local leaderboard and requests geolocation', async () => {
    render(<Leaderboard />);
    
    // Open scope filter dropdown
    fireEvent.click(screen.getByRole('combobox', { name: /Scope/i }));
    
    // Wait for dropdown to open
    await waitFor(() => {
      expect(screen.getByText('Local (5 Miles)')).toBeInTheDocument();
    });
    
    // Select 'Local (5 Miles)' scope
    fireEvent.click(screen.getByText('Local (5 Miles)'));
    
    // Verify geolocation was requested
    expect(mockGeolocation.getCurrentPosition).toHaveBeenCalled();
    
    // Verify that the filter has been applied
    await waitFor(() => {
      expect(screen.getByText(/Top Performers - .* \(Local \(5 Miles\)\)/i)).toBeInTheDocument();
    });
  });

  it('shows empty state when no results', async () => {
    // Mock implementation to return empty data
    vi.mock('../Leaderboard', async (importOriginal) => {
      const mod = await importOriginal() as { default: React.ComponentType<unknown>; mockLeaderboard?: unknown[] };
      return {
        ...mod,
        mockLeaderboard: [],
      };
    });
    
    render(<Leaderboard />);
    
    // Force empty state by setting a filter that won't match any data
    fireEvent.click(screen.getByRole('combobox', { name: /Exercise/i }));
    await waitFor(() => {
      expect(screen.getByText('Overall')).toBeInTheDocument();
    });
    
    // Eventually we should see the empty state
    await waitFor(() => {
      expect(screen.getByTestId('lottie-player')).toBeInTheDocument();
      expect(screen.getByText(/No rankings found/i)).toBeInTheDocument();
    });
  });
}); 