import React, { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './lib/authContext';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Create a fresh Query Client for each test
const createTestQueryClient = () => 
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        cacheTime: Infinity,
      },
      mutations: {
        retry: false,
      },
    },
  });

interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  route?: string;
  routePath?: string;
  authenticated?: boolean;
  user?: Record<string, any>;
  queryClient?: QueryClient;
}

/**
 * Custom render function that wraps components with necessary providers
 */
function customRender(
  ui: ReactElement,
  {
    route = '/',
    routePath = '/',
    authenticated = false,
    user = null,
    queryClient = createTestQueryClient(),
    ...renderOptions
  }: CustomRenderOptions = {}
) {
  const Wrapper = ({ children }: { children: React.ReactNode }) => {
    return (
      <QueryClientProvider client={queryClient}>
        <AuthProvider initialState={{ authenticated, user }}>
          <MemoryRouter initialEntries={[route]}>
            <Routes>
              <Route path={routePath} element={children} />
            </Routes>
          </MemoryRouter>
        </AuthProvider>
      </QueryClientProvider>
    );
  };

  return render(ui, { wrapper: Wrapper, ...renderOptions });
}

// Re-export everything from testing-library
export * from '@testing-library/react';

// Override render method
export { customRender as render }; 