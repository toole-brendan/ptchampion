import React from "react";
import { Meta, StoryObj } from "@storybook/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import Leaderboard from "../pages/Leaderboard";
// We need to install msw if not already installed
// Using type definitions for mock service worker
import { rest, RestRequest, ResponseComposition, RestContext } from "msw";

// Create a client for React Query
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});

// Create a decorator to provide the QueryClient
const withReactQuery = (Story: React.ComponentType) => (
  <QueryClientProvider client={queryClient}>
    <Story />
  </QueryClientProvider>
);

// MSW handlers to mock API responses
const handlers = [
  // Default leaderboard data
  rest.get("/api/v1/leaderboard/overall", (
    req: RestRequest, 
    res: ResponseComposition, 
    ctx: RestContext
  ) => {
    return res(
      ctx.json([
        {
          user_id: 1,
          username: "top_user",
          display_name: "Top User",
          max_grade: 100,
          last_attempt_date: new Date().toISOString(),
        },
        {
          user_id: 2,
          username: "second_user",
          display_name: "Second User",
          max_grade: 95,
          last_attempt_date: new Date().toISOString(),
        },
        {
          user_id: 3,
          username: "third_user",
          display_name: "Third User",
          max_grade: 90,
          last_attempt_date: new Date().toISOString(),
        },
        {
          user_id: 4,
          username: "fourth_user",
          display_name: "Fourth User",
          max_grade: 85,
          last_attempt_date: new Date().toISOString(),
        },
        {
          user_id: 5,
          username: "fifth_user",
          display_name: "Fifth User",
          max_grade: 80,
          last_attempt_date: new Date().toISOString(),
        },
      ])
    );
  }),
  
  // Empty leaderboard
  rest.get("/api/v1/leaderboard/pullup", (
    req: RestRequest, 
    res: ResponseComposition, 
    ctx: RestContext
  ) => {
    return res(ctx.json([]));
  }),
  
  // Error response
  rest.get("/api/v1/leaderboard/situp", (
    req: RestRequest, 
    res: ResponseComposition, 
    ctx: RestContext
  ) => {
    return res(ctx.status(500), ctx.json({ error: "Server error" }));
  }),
  
  // Local leaderboard
  rest.get("/api/v1/leaderboard/overall", (
    req: RestRequest, 
    res: ResponseComposition, 
    ctx: RestContext
  ) => {
    // Check if this is a local request with lat/lng params
    const lat = req.url.searchParams.get("lat");
    const lng = req.url.searchParams.get("lng");
    
    if (lat && lng) {
      return res(
        ctx.json([
          {
            user_id: 6,
            username: "local_user",
            display_name: "Local User",
            max_grade: 98,
            last_attempt_date: new Date().toISOString(),
          },
        ])
      );
    }
    
    // If not a local request, return normal data
    return res(
      ctx.json([
        {
          user_id: 1,
          username: "top_user",
          display_name: "Top User",
          max_grade: 100,
          last_attempt_date: new Date().toISOString(),
        },
      ])
    );
  }),
];

const meta: Meta<typeof Leaderboard> = {
  title: "Pages/Leaderboard",
  component: Leaderboard,
  decorators: [withReactQuery],
  parameters: {
    layout: "fullscreen",
    msw: {
      handlers,
    },
  },
};

export default meta;
type Story = StoryObj<typeof Leaderboard>;

// Default story with data
export const Default: Story = {
  parameters: {
    msw: {
      handlers: [
        rest.get("/api/v1/leaderboard/:exerciseType", (
          req: RestRequest, 
          res: ResponseComposition, 
          ctx: RestContext
        ) => {
          return res(
            ctx.json([
              {
                user_id: 1,
                username: "top_user",
                display_name: "Top User",
                max_grade: 100,
                last_attempt_date: new Date().toISOString(),
              },
              {
                user_id: 2,
                username: "second_user",
                display_name: "Second User",
                max_grade: 95,
                last_attempt_date: new Date().toISOString(),
              },
              {
                user_id: 3,
                username: "third_user",
                display_name: "Third User",
                max_grade: 90,
                last_attempt_date: new Date().toISOString(),
              },
            ])
          );
        }),
      ],
    },
  },
};

// Loading state
export const Loading: Story = {
  parameters: {
    msw: {
      handlers: [
        rest.get("/api/v1/leaderboard/:exerciseType", (
          req: RestRequest, 
          res: ResponseComposition, 
          ctx: RestContext
        ) => {
          // Delay the response to show loading state
          return res(ctx.delay(10000), ctx.json([]));
        }),
      ],
    },
  },
};

// Empty state
export const Empty: Story = {
  parameters: {
    msw: {
      handlers: [
        rest.get("/api/v1/leaderboard/:exerciseType", (
          req: RestRequest, 
          res: ResponseComposition, 
          ctx: RestContext
        ) => {
          return res(ctx.json([]));
        }),
      ],
    },
  },
};

// Error state
export const Error: Story = {
  parameters: {
    msw: {
      handlers: [
        rest.get("/api/v1/leaderboard/:exerciseType", (
          req: RestRequest, 
          res: ResponseComposition, 
          ctx: RestContext
        ) => {
          return res(ctx.status(500), ctx.json({ error: "Failed to load leaderboard data" }));
        }),
      ],
    },
  },
};

// Local leaderboard
export const LocalLeaderboard: Story = {
  parameters: {
    msw: {
      handlers: [
        rest.get("/api/v1/leaderboard/:exerciseType", (
          req: RestRequest, 
          res: ResponseComposition, 
          ctx: RestContext
        ) => {
          const lat = req.url.searchParams.get("lat");
          const lng = req.url.searchParams.get("lng");
          
          if (lat && lng) {
            return res(
              ctx.json([
                {
                  user_id: 6,
                  username: "local_user",
                  display_name: "Local Champion",
                  max_grade: 98,
                  last_attempt_date: new Date().toISOString(),
                },
              ])
            );
          }
          
          return res(ctx.json([]));
        }),
      ],
    },
  },
};

const mockUsers = [
  { id: '1', name: 'John Smith', rank: 1, avatar: '/path/to/avatar1.jpg', score: 245, unit: 'pts' },
  { id: '2', name: 'Jane Doe', rank: 2, avatar: '/path/to/avatar2.jpg', score: 230, unit: 'pts' },
  { id: '3', name: 'Robert Johnson', rank: 3, avatar: '/path/to/avatar3.jpg', score: 215, unit: 'pts' },
  { id: '4', name: 'Emily Davis', rank: 4, avatar: '/path/to/avatar4.jpg', score: 200, unit: 'pts' },
  { id: '5', name: 'William Brown', rank: 5, avatar: '/path/to/avatar5.jpg', score: 185, unit: 'pts' },
  { id: '6', name: 'Sarah Lee', rank: 6, avatar: '/path/to/avatar6.jpg', score: 170, unit: 'pts' },
  { id: '7', name: 'David Miller', rank: 7, avatar: '/path/to/avatar7.jpg', score: 155, unit: 'pts' },
  { id: '8', name: 'Laura Wilson', rank: 8, avatar: '/path/to/avatar8.jpg', score: 140, unit: 'pts' },
  { id: '9', name: 'Michael Taylor', rank: 9, avatar: '/path/to/avatar9.jpg', score: 125, unit: 'pts' },
  { id: '10', name: 'Jennifer Anderson', rank: 10, avatar: '/path/to/avatar10.jpg', score: 110, unit: 'pts' },
];

export const PushupLeaderboard: Story = {
  args: {
    exercise: 'pushups',
    timeframe: 'week',
    users: mockUsers,
    loading: false,
    userRank: 6,
  },
};

export const SitupLeaderboard: Story = {
  args: {
    exercise: 'situps',
    timeframe: 'month',
    users: mockUsers,
    loading: false,
    userRank: 3,
  },
};

export const RunningLeaderboard: Story = {
  args: {
    exercise: 'running',
    timeframe: 'year',
    users: mockUsers.map(user => ({
      ...user,
      score: user.rank * 1.5,
      unit: 'mi'
    })),
    loading: false,
    userRank: 10,
  },
};

export const Loading: Story = {
  args: {
    exercise: 'pushups',
    timeframe: 'week',
    users: [],
    loading: true,
    userRank: null,
  },
}; 