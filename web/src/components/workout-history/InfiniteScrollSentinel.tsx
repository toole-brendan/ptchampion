import React, { useEffect, useRef } from 'react';
import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface InfiniteScrollSentinelProps {
  onLoadMore: () => void;
  isFetchingNextPage: boolean;
  hasNextPage: boolean | undefined;
}

const InfiniteScrollSentinel: React.FC<InfiniteScrollSentinelProps> = ({
  onLoadMore,
  isFetchingNextPage,
  hasNextPage
}) => {
  const sentinelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && hasNextPage && !isFetchingNextPage) {
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

  if (!hasNextPage) {
    return (
      <div className="py-4 text-center text-sm font-medium text-tactical-gray">
        You've reached the end of your workout history.
      </div>
    );
  }

  return (
    <div 
      ref={sentinelRef} 
      className="flex items-center justify-center py-6"
    >
      {isFetchingNextPage ? (
        <div className="flex items-center gap-2">
          <Loader2 className="size-5 animate-spin text-brass-gold" />
          <span className="text-sm font-medium text-tactical-gray">Loading more...</span>
        </div>
      ) : (
        <span className="text-sm font-medium text-tactical-gray">Scroll to load more</span>
      )}
    </div>
  );
};

export default InfiniteScrollSentinel; 