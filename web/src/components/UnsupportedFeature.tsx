import React from 'react';
import { Smartphone, AlertCircle } from 'lucide-react';
import { Card, CardContent } from './ui/card';
import { Text } from './ui/typography';

interface UnsupportedFeatureProps {
  title: string;
  description: string;
  mobileOnly?: boolean;
  className?: string;
}

export default function UnsupportedFeature({ 
  title,
  description,
  mobileOnly = false,
  className
}: UnsupportedFeatureProps) {
  return (
    <Card variant="default" className={`bg-cream-dark/50 ${className}`}>
      <CardContent className="pt-md">
        <div className="flex flex-col items-center text-center space-y-4">
          {mobileOnly ? (
            <div className="rounded-full bg-brass-gold/20 p-3">
              <Smartphone className="h-6 w-6 text-brass-gold" />
            </div>
          ) : (
            <div className="rounded-full bg-warning/20 p-3">
              <AlertCircle className="h-6 w-6 text-warning" />
            </div>
          )}
          
          <h3 className="font-heading text-heading4">{title}</h3>
          <Text variant="body">{description}</Text>
          
          {mobileOnly && (
            <div className="bg-brass-gold/10 rounded-md p-sm w-full">
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