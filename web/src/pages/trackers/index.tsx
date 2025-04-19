import React from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowRight, Activity, Dumbbell, Zap, Wind } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

// Define tracking exercise types
const trackerTypes = [
  { 
    name: "Push-ups", 
    icon: Activity, 
    path: '/trackers/pushups',
    description: "Track push-up form and repetitions with real-time analysis"
  },
  { 
    name: "Pull-ups", 
    icon: Dumbbell, 
    path: '/trackers/pullups',
    description: "Track pull-up performance and form with live feedback" 
  },
  { 
    name: "Sit-ups", 
    icon: Zap, 
    path: '/trackers/situps',
    description: "Count sit-ups and analyze your technique with form scoring" 
  },
  { 
    name: "Running", 
    icon: Wind, 
    path: '/trackers/running',
    description: "Track pace, distance, and running metrics with GPS" 
  },
];

export function TrackersIndex() {
  const navigate = useNavigate();

  const handleSelectTracker = (tracker: typeof trackerTypes[0]) => {
    // All trackers are now implemented
    navigate(tracker.path);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="mb-6 font-heading text-3xl tracking-wide text-command-black">Exercise Trackers</h1>
      
      <p className="mb-6 text-tactical-gray">
        Select an exercise to begin tracking your form and performance using computer vision analysis.
      </p>
      
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        {trackerTypes.map((tracker) => (
          <Card 
            key={tracker.name} 
            className="cursor-pointer bg-cream transition-all hover:shadow-md"
            onClick={() => handleSelectTracker(tracker)}
          >
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="rounded-full bg-brass-gold/10 p-2">
                    <tracker.icon className="size-6 text-brass-gold" />
                  </div>
                  <CardTitle className="font-heading text-xl">{tracker.name}</CardTitle>
                </div>
                <ArrowRight className="size-5 text-brass-gold" />
              </div>
              <CardDescription className="mt-2">{tracker.description}</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-1 text-xs font-medium text-green-600">
                <span className="inline-block size-2 rounded-full bg-green-600"></span>
                Available Now
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
} 