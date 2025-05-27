import { useState, useEffect } from 'react';

interface UseStaggeredAnimationOptions {
  itemCount: number;
  baseDelay?: number;
  staggerDelay?: number;
}

export const useStaggeredAnimation = ({
  itemCount,
  baseDelay = 100,
  staggerDelay = 100
}: UseStaggeredAnimationOptions) => {
  const [visibleItems, setVisibleItems] = useState<boolean[]>(
    new Array(itemCount).fill(false)
  );

  useEffect(() => {
    // Reset all items to hidden when count changes
    setVisibleItems(new Array(itemCount).fill(false));

    // Create staggered timeouts
    const timeouts = Array.from({ length: itemCount }, (_, index) =>
      setTimeout(() => {
        setVisibleItems(prev => {
          const newState = [...prev];
          newState[index] = true;
          return newState;
        });
      }, baseDelay + (index * staggerDelay))
    );

    // Cleanup function
    return () => {
      timeouts.forEach(timeout => clearTimeout(timeout));
    };
  }, [itemCount, baseDelay, staggerDelay]);

  return visibleItems;
};

export default useStaggeredAnimation; 