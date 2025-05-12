# PT Champion - Workout History Feature

This document provides an overview of the Workout History feature in PT Champion web application. The history section includes a list view of past workouts and a detailed view for each workout.

## Features

### WorkoutHistoryView

The main history page displays:

- **Streak Banner**: Shows consecutive workout day streaks
- **Filters**:
  - Time period tabs (All, Week, Month, Year)
  - Custom date range picker
  - Exercise type filter
- **Stats Summary**: Shows totals for workouts, time, reps, and distance
- **Personal Records**: Displays best performances for each exercise type
- **Workout List**: Displays cards for each workout with infinite scrolling

### HistoryDetail

The detail page for a specific workout shows:

- **Basic Info**: Exercise type, date, time
- **Metrics**: Reps/distance, duration
- **Performance**: Form score with progress bar and letter grade
- **Charts**: Performance charts for workouts with rep series or pace data
- **Notes**: Workout notes if available
- **Share**: Button to share workout results via Web Share API or clipboard

## Component Structure

- **WorkoutCard**: Displays a single workout entry
- **HistoryFilterBar**: Contains time period tabs and filters
- **StreakBanner**: Shows workout streak information
- **InfiniteScrollSentinel**: Triggers loading more workout items when scrolled into view

## Data Flow

1. `useInfiniteHistory` hook handles data fetching with pagination
2. Filters applied client-side for smooth user experience
3. Scroll position is preserved when navigating between list and detail views

## Technical Details

### API Integration

- Uses React Query for data fetching, caching and pagination
- Endpoint: `GET /exercises` for paginated list
- Endpoint: `GET /exercises/:id` for detail view

### State Management

- Filter state managed locally in the WorkoutHistoryView component
- Scroll position tracked via React Router's location state
- Exercises cached with React Query's cache mechanism

### Testing

- Unit tests for WorkoutCard component
- E2E tests verify history list loading, filtering, navigation, and sharing

## Development

To add new features or modify the history pages:

1. Use the existing component structure to maintain consistency
2. Follow the military-style design language with brass-gold accents
3. Test changes with both unit and E2E tests

## Future Enhancements

- Server-side filtering for better performance with large workout histories
- Advanced analytics and trends visualization
- Export data functionality to CSV/PDF
- Filtering by score ranges 