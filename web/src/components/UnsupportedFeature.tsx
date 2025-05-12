import React from 'react';
import { Smartphone, AlertCircle } from 'lucide-react';
import { Card, CardContent } from './ui/card';
import { Text } from './ui/typography';

export interface UnsupportedFeatureProps {
  title?: string;
  description?: string;
  mobileOnly?: boolean;
  className?: string;
}

export default function UnsupportedFeature({
  title = "Feature Not Available",
  description = "This feature is not supported on your current device or browser.",
  mobileOnly = false,
  className
}: UnsupportedFeatureProps) {
  return (
    <Card variant="default" className={`bg-cream-dark bg-opacity-50 ${className}`}>
      <CardContent className="pt-md">
        <div className="flex flex-col items-center space-y-4 text-center">
          {mobileOnly ? (
            <div className="bg-brass-gold bg-opacity-20 rounded-full p-3">
              <Smartphone className="size-6 text-brass-gold" />
            </div>
          ) : (
            <div className="bg-warning bg-opacity-20 rounded-full p-3">
              <AlertCircle className="size-6 text-warning" />
            </div>
          )}
          
          <h3 className="font-heading text-heading4">{title}</h3>
          <Text variant="body">{description}</Text>
          
          {mobileOnly && (
            <div className="bg-brass-gold bg-opacity-10 w-full rounded-md p-sm">
              <Text variant="small" weight="semibold">
                This feature is available in our mobile app
              </Text>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
} 