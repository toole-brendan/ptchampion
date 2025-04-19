import React from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowRight, Zap, TrendingUp, Activity, PersonStanding } from 'lucide-react'; // Import icons
import { useNavigate } from 'react-router-dom'; // Import useNavigate
import { cn } from "@/lib/utils"; // Import cn

// Define exercise types
const exerciseTypes = [
  { name: "Push-ups", icon: Activity, path: '/exercises/pushup' },
  { name: "Sit-ups", icon: Zap, path: '/exercises/situp' }, // Using Zap for Sit-ups
  { name: "Pull-ups", icon: PersonStanding, path: '/exercises/pullup' }, // Using PersonStanding for Pull-ups
  { name: "Running", icon: TrendingUp, path: '/exercises/run' },
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

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-foreground">Exercises</h1>

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
                  "hover:bg-muted/50 hover:border-border focus:ring-primary/50"
                )}
                onClick={() => handleSelectExercise(exercise.path)}
              >
                <div className="flex items-center space-x-3">
                  <exercise.icon className="size-5 text-primary" />
                  <span className="font-medium text-foreground">{exercise.name}</span>
                </div>
                <ArrowRight className="size-4 text-muted-foreground" />
              </Button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Placeholder for active session UI if needed */}

    </div>
  );
};

export default Exercises; 