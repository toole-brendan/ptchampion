import React, { useEffect, useRef } from 'react';
import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface InfiniteScrollSentinelProps {
  onLoadMore: () => void;
  isFetchingNextPage: boolean;
  hasNextPage: boolean | undefined;
}

export const InfiniteScrollSentinel: React.FC<InfiniteScrollSentinelProps> = ({
  onLoadMore,
  isFetchingNextPage,
  hasNextPage,
}) => {
  const sentinelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        // If the sentinel is visible and we have more pages to load
        if (entries[0]?.isIntersecting && hasNextPage && !isFetchingNextPage) {
          onLoadMore();
        }
      },
      { threshold: 0.5 }
    );

    const currentSentinel = sentinelRef.current;
    if (currentSentinel) {
      observer.observe(currentSentinel);
    }

    return () => {
      if (currentSentinel) {
        observer.unobserve(currentSentinel);
      }
    };
  }, [onLoadMore, hasNextPage, isFetchingNextPage]);

  // If no more pages, don't render anything
  if (!hasNextPage && !isFetchingNextPage) {
    return null;
  }

  return (
    <div className="my-6 flex flex-col items-center" aria-hidden="true">
      {/* Hidden sentinel div that triggers loading when visible */}
      <div ref={sentinelRef} className="h-4 w-full" />
      
      {/* Loading indicator or button fallback */}
      {isFetchingNextPage ? (
        <div className="flex items-center">
          <Loader2 className="mr-2 size-5 animate-spin text-brass-gold" />
          <span className="text-sm text-tactical-gray">Loading more workouts...</span>
        </div>
      ) : hasNextPage ? (
        <Button 
          variant="outline" 
          onClick={onLoadMore}
          className="hover:bg-brass-gold/10 border-brass-gold text-brass-gold"
        >
          Load More
        </Button>
      ) : (
        <p className="text-sm text-tactical-gray">No more workouts to load</p>
      )}
    </div>
  );
};

export default InfiniteScrollSentinel; 