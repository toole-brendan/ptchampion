import React from 'react';
import { Button } from "@/components/ui/button";
import { ArrowRight, Activity, Dumbbell, Zap, Wind, ChevronLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

// Military-style corner component
const MilitaryCorners: React.FC = () => (
  <>
    {/* Military corner cutouts - top left and right */}
    <div className="absolute left-0 top-0 size-[15px] bg-background"></div>
    <div className="absolute right-0 top-0 size-[15px] bg-background"></div>
    
    {/* Military corner cutouts - bottom left and right */}
    <div className="absolute bottom-0 left-0 size-[15px] bg-background"></div>
    <div className="absolute bottom-0 right-0 size-[15px] bg-background"></div>
    
    {/* Diagonal lines for corners */}
    <div className="bg-tactical-gray/50 absolute left-0 top-0 h-px w-[15px] origin-top-left rotate-45"></div>
    <div className="bg-tactical-gray/50 absolute right-0 top-0 h-px w-[15px] origin-top-right -rotate-45"></div>
    <div className="bg-tactical-gray/50 absolute bottom-0 left-0 h-px w-[15px] origin-bottom-left -rotate-45"></div>
    <div className="bg-tactical-gray/50 absolute bottom-0 right-0 h-px w-[15px] origin-bottom-right rotate-45"></div>
  </>
);

// Header divider component
const HeaderDivider: React.FC = () => (
  <div className="mx-auto my-2 h-px w-16 bg-brass-gold"></div>
);

// Define tracking exercise types - all marked as available since we now have all trackers from exercises/
const trackerTypes = [
  { 
    name: "Push-ups", 
    icon: Activity, 
    path: '/trackers/pushups',
    description: "Track push-up form and repetitions with real-time analysis",
    available: true
  },
  { 
    name: "Pull-ups", 
    icon: Dumbbell, 
    path: '/trackers/pullups',
    description: "Track pull-up performance and form with live feedback",
    available: true
  },
  { 
    name: "Sit-ups", 
    icon: Zap, 
    path: '/trackers/situps',
    description: "Count sit-ups and analyze your technique with form scoring",
    available: true
  },
  { 
    name: "Running", 
    icon: Wind, 
    path: '/trackers/running',
    description: "Track pace, distance, and running metrics with GPS",
    available: true
  },
];

export default function TrackerIndex() {
  const navigate = useNavigate();

  const handleSelectTracker = (path: string, available: boolean) => {
    if (available) {
      navigate(path);
    }
  };

  return (
    <div className="space-y-6">
      {/* Back button */}
      <Button 
        variant="outline" 
        onClick={() => navigate('/exercises')} 
        className="hover:bg-tactical-gray/10 mb-4 border-tactical-gray text-tactical-gray"
      >
        <ChevronLeft className="mr-2 size-4" /> Back to Exercises
      </Button>
      
      {/* Page title with military styling */}
      <div className="bg-card-background relative overflow-hidden rounded-card p-content shadow-medium">
        <MilitaryCorners />
        <div className="mb-4 text-center">
          <h2 className="font-heading text-heading3 uppercase tracking-wider text-command-black">
            Advanced Trackers
          </h2>
          <HeaderDivider />
          <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">Track your performance with enhanced detection</p>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {trackerTypes.map((tracker) => (
          <div
            key={tracker.name}
            className={`bg-card-background relative overflow-hidden rounded-card shadow-medium transition-all ${
              tracker.available 
                ? "cursor-pointer hover:-translate-y-1 hover:shadow-large" 
                : "opacity-75"
            }`}
            onClick={() => handleSelectTracker(tracker.path, tracker.available)}
          >
            <MilitaryCorners />
            <div className="flex items-start p-content">
              <div className="bg-brass-gold/10 mr-4 rounded-full p-3">
                <tracker.icon className="size-6 text-brass-gold" />
              </div>
              <div className="flex-1">
                <h3 className="font-heading text-lg uppercase tracking-wider text-command-black">
                  {tracker.name}
                </h3>
                <p className="text-sm text-tactical-gray">{tracker.description}</p>
              </div>
              <ArrowRight className="size-5 self-center text-brass-gold" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
} 