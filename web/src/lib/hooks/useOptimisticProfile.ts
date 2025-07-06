import { useMutation, useQueryClient } from '@tanstack/react-query';
import { updateCurrentUser } from '@/lib/apiClient';
import { UserResponse } from '@/lib/types';
import { logger } from '@/lib/logger';

interface ProfileMutationContext {
  previousUser?: UserResponse;
}

export function useOptimisticProfile() {
  const queryClient = useQueryClient();

  return useMutation<UserResponse, Error, Partial<UserResponse>, ProfileMutationContext>({
    mutationFn: (updates) => updateCurrentUser(updates),
    
    // Optimistically update the cache before the request completes
    onMutate: async (updates) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['currentUser'] });

      // Snapshot the previous user
      const previousUser = queryClient.getQueryData<UserResponse>(['currentUser']);

      // Optimistically update the user
      queryClient.setQueryData(['currentUser'], (old: UserResponse | undefined) => {
        if (!old) return old;
        return {
          ...old,
          ...updates,
          // Preserve certain fields that shouldn't be overwritten
          id: old.id,
          created_at: old.created_at,
          updated_at: new Date().toISOString(),
        };
      });

      // Return context with previous user for rollback
      return { previousUser };
    },

    // On error, roll back to the previous value
    onError: (err, updates, context) => {
      logger.error('Failed to update profile:', err);
      
      if (context?.previousUser) {
        queryClient.setQueryData(['currentUser'], context.previousUser);
      }
    },

    // Always refetch after error or success to ensure sync
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['currentUser'] });
    },
  });
}