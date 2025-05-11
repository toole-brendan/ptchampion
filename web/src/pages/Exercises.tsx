// import React from 'react'; // Removed unused import
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowRight, Zap, TrendingUp, Activity, PersonStanding, InfoIcon, Star } from 'lucide-react'; // Import additional icons
import { useNavigate } from 'react-router-dom'; // Import useNavigate
import { cn } from "@/lib/utils"; // Restored cn import
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";

// Define exercise types
const exerciseTypes = [
  { name: "Push-ups", icon: Activity, path: '/exercises/pushups', improvedVersion: true },
  { name: "Sit-ups", icon: Zap, path: '/exercises/situps' }, // Using Zap for Sit-ups
  { name: "Pull-ups", icon: PersonStanding, path: '/exercises/pullups' }, // Using PersonStanding for Pull-ups
  { name: "Running", icon: TrendingUp, path: '/exercises/running' },
];

const Exercises: React.FC = () => {
  const navigate = useNavigate(); // Initialize navigate

  const handleSelectExercise = (path: string | undefined) => {
    if (path) {
      navigate(path);
    } else {
      console.warn("No path defined for this exercise.");
      // Optionally show an alert or notification
      // alert("Tracking for this exercise is not available yet.");
    }
  };

  const handleGoToTrackers = () => {
    navigate('/trackers');
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-foreground">Exercises</h1>

      <Alert className="rounded-card bg-olive-mist/10 border-army-tan/40">
        <InfoIcon className="size-4 text-brass-gold" />
        <AlertTitle className="text-sm font-semibold text-command-black">Advanced Trackers Available</AlertTitle>
        <AlertDescription className="text-tactical-gray">
          Try our improved exercise trackers with better form detection, offline support, and military styling.
          <Button
            onClick={handleGoToTrackers}
            variant="outline"
            size="sm"
            className="ml-2 border-brass-gold text-brass-gold hover:bg-brass-gold/10"
          >
            View Advanced Trackers
          </Button>
        </AlertDescription>
      </Alert>

      <Card className="transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="text-lg font-semibold">Start Training</CardTitle>
          <CardDescription>Select an exercise to begin tracking your performance.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
            {exerciseTypes.map((exercise) => (
              <Button
                key={exercise.name}
                variant="outline"
                className={cn(
                  "justify-between h-auto text-left p-4 transition-colors",
                  "hover:bg-muted/50 hover:border-border focus:ring-primary/50",
                  exercise.improvedVersion && "border-brass-gold/30"
                )}
                onClick={() => handleSelectExercise(exercise.path)}
              >
                <div className="flex items-center space-x-3">
                  <exercise.icon className={cn("size-5", exercise.improvedVersion ? "text-brass-gold" : "text-primary")} />
                  <span className="font-medium text-foreground">{exercise.name}</span>
                  {exercise.improvedVersion && (
                    <span className="rounded-full bg-brass-gold/10 px-2 py-0.5 text-xs font-medium text-brass-gold">
                      <Star className="mr-1 inline-block size-3" /> Enhanced
                    </span>
                  )}
                </div>
                <ArrowRight className="size-4 text-muted-foreground" />
              </Button>
            ))}
          </div>
        </CardContent>
        <CardFooter className="border-t px-6 py-4">
          <Button 
            variant="outline" 
            className="w-full border-brass-gold text-brass-gold hover:bg-brass-gold/10"
            onClick={handleGoToTrackers}
          >
            View All Advanced Trackers
          </Button>
        </CardFooter>
      </Card>

      {/* Placeholder for active session UI if needed */}

    </div>
  );
};

export default Exercises; 