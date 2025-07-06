import React, { useState } from 'react';

interface OptimizedImageProps extends React.ImgHTMLAttributes<HTMLImageElement> {
  src: string;
  fallbackSrc?: string;
  webpSrc?: string;
  loading?: 'lazy' | 'eager';
}

export const OptimizedImage: React.FC<OptimizedImageProps> = ({
  src,
  fallbackSrc,
  webpSrc,
  loading = 'lazy',
  alt,
  ...props
}) => {
  const [error, setError] = useState(false);
  const [currentSrc, setCurrentSrc] = useState(webpSrc || src);

  const handleError = () => {
    if (!error && fallbackSrc) {
      setError(true);
      setCurrentSrc(fallbackSrc);
    }
  };

  return (
    <picture>
      {webpSrc && (
        <source srcSet={webpSrc} type="image/webp" />
      )}
      <img
        src={currentSrc}
        alt={alt}
        loading={loading}
        onError={handleError}
        {...props}
      />
    </picture>
  );
};