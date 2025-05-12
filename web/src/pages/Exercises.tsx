// import React from 'react'; // Removed unused import
import { useNavigate } from 'react-router-dom';
import { 
  SectionCard, 
  QuickLinkCard 
} from '@/components/ui/card';
import { Button } from "@/components/ui/button";
import { 
  Play, 
  Activity, 
  Zap, 
  PersonStanding, 
  TrendingUp 
} from 'lucide-react';

// Import the exercise PNG images with explicit paths to ensure they're found
import pushupImage from '../assets/pushup.png';
import pullupImage from '../assets/pullup.png';
import situpImage from '../assets/situp.png';
import runningImage from '../assets/running.png';

// Define exercise types - normalized with consistent naming
const exerciseTypes = [
  { name: "PUSH-UPS", image: pushupImage, icon: Activity, path: '/exercises/pushups' },
  { name: "SIT-UPS", image: situpImage, icon: Zap, path: '/exercises/situps' }, 
  { name: "PULL-UPS", image: pullupImage, icon: PersonStanding, path: '/exercises/pullups' }, 
  { name: "RUNNING", image: runningImage, icon: TrendingUp, path: '/exercises/running' },
];

const Exercises: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="bg-cream min-h-screen px-4 py-section md:py-12 lg:px-8">
      <div className="flex flex-col space-y-section max-w-7xl mx-auto">
        {/* Page Header - full-width, no card, left aligned */}
        <header className="text-left mb-section animate-fade-in px-content">
          <h1 className="font-heading text-heading3 md:text-heading2 uppercase tracking-wider text-deep-ops">
            Exercises
          </h1>

          {/* thin gold separator, left aligned */}
          <div className="my-4 h-px w-24 bg-brass-gold" />

          <p className="text-sm md:text-base font-semibold tracking-wide text-deep-ops">
            Select an exercise to begin tracking
          </p>
        </header>

        {/* Main Exercise Selection Section */}
        <SectionCard
          title="Start Training"
          description="Choose an exercise to begin a new session"
          icon={<Play className="size-5" />}
          className="animate-fade-in animation-delay-100"
          showDivider
        >
          <div className="flex justify-end mb-4">
            <Button 
              className="bg-brass-gold text-deep-ops shadow-small"
              onClick={() => navigate('/history')}
            >
              VIEW HISTORY
            </Button>
          </div>
          
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            {exerciseTypes.map((exercise, index) => (
              <QuickLinkCard
                key={exercise.name}
                title={exercise.name}
                icon={<img 
                  src={exercise.image} 
                  alt={exercise.name} 
                  className="h-10 w-auto object-contain" 
                />}
                onClick={() => navigate(exercise.path)}
                className="bg-cream p-4"
                style={{animationDelay: `${index * 100}ms`}}
                tabIndex={0}
                role="button"
              />
            ))}
          </div>
        </SectionCard>
      </div>
    </div>
  );
};

export default Exercises; 