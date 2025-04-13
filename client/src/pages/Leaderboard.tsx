import React, { useState, useMemo } from 'react';
import {
    Table,
    TableBody,
    TableCaption,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
  } from "@/components/ui/table";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"; // For user avatars
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"; // For filtering
import { Label } from "@/components/ui/label"; // For filter labels
import { cn } from "@/lib/utils"; // Import cn utility

// Mock data for leaderboard
const mockLeaderboard = [
  { rank: 1, name: 'Alex Johnson', score: 1550, exercise: 'Overall', avatar: 'https://github.com/shadcn.png' },
  { rank: 2, name: 'Maria Garcia', score: 1480, exercise: 'Overall', avatar: null },
  { rank: 3, name: 'Brendan Toole', score: 1450, exercise: 'Overall', avatar: 'https://github.com/brendantoole.png' },
  { rank: 4, name: 'Kenji Tanaka', score: 1390, exercise: 'Overall', avatar: null },
  { rank: 5, name: 'Fatima Ahmed', score: 1350, exercise: 'Overall', avatar: null },
  { rank: 1, name: 'Alex Johnson', score: 45, exercise: 'Push-ups', avatar: 'https://github.com/shadcn.png' },
  { rank: 2, name: 'Brendan Toole', score: 42, exercise: 'Push-ups', avatar: 'https://github.com/brendantoole.png' },
  { rank: 3, name: 'Maria Garcia', score: 40, exercise: 'Push-ups', avatar: null },
  { rank: 1, name: 'Kenji Tanaka', score: 65, exercise: 'Sit-ups', avatar: null },
  { rank: 2, name: 'Fatima Ahmed', score: 62, exercise: 'Sit-ups', avatar: null },
  { rank: 3, name: 'Alex Johnson', score: 60, exercise: 'Sit-ups', avatar: 'https://github.com/shadcn.png' },
  { rank: 1, name: 'Maria Garcia', score: 15, exercise: 'Pull-ups', avatar: null },
  { rank: 2, name: 'Alex Johnson', score: 12, exercise: 'Pull-ups', avatar: 'https://github.com/shadcn.png' },
  { rank: 1, name: 'Brendan Toole', score: 5.2, exercise: 'Running', avatar: 'https://github.com/brendantoole.png' }, // Score = km for running?
  { rank: 2, name: 'Fatima Ahmed', score: 4.8, exercise: 'Running', avatar: null },
];

const exerciseOptions = ['Overall', 'Push-ups', 'Sit-ups', 'Pull-ups', 'Running'];
const scopeOptions = ['Global', 'Local (5 Miles)']; // Local needs implementation

// Helper to get initials from name
const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((n) => n[0])
      .join('');
  };

const Leaderboard: React.FC = () => {
  const [exerciseFilter, setExerciseFilter] = useState<string>(exerciseOptions[0]); // Default to Overall
  const [scopeFilter, setScopeFilter] = useState<string>(scopeOptions[0]); // Default to Global

  // Filter leaderboard data based on selections
  const filteredLeaderboard = useMemo(() => {
    // TODO: Implement actual local filtering based on user location
    if (scopeFilter === scopeOptions[1]) {
        // For now, just return a message or empty array for Local
        console.warn("Local leaderboard filtering not implemented.");
        // return []; 
        // Or maybe filter by exercise but show a note about scope?
    }
    
    return mockLeaderboard
        .filter(user => user.exercise === exerciseFilter) // Filter by selected exercise
        .sort((a, b) => a.rank - b.rank); // Ensure sorted by rank
        // .slice(0, 10); // Optionally limit to top N results

  }, [exerciseFilter, scopeFilter]);

  // Dynamically set the card title
  const cardTitle = `Top Performers - ${exerciseFilter} (${scopeFilter})`;

  return (
    <div className="space-y-6"> {/* Reduced vertical spacing */}
      <h1 className="text-2xl font-semibold text-foreground">Leaderboard</h1> {/* Standardized heading */}
      
      {/* Filter Controls - Moved inside CardContent */}
      {/* <div className="flex flex-col sm:flex-row gap-4 mb-6"> ... </div> */}

      {/* Leaderboard Table Card */}
      <Card className="bg-card rounded-lg shadow-sm border border-border transition-shadow hover:shadow-md"> {/* Added hover effect */}
        <CardHeader>
          <CardTitle className="text-lg font-semibold">{cardTitle}</CardTitle> {/* Standardized card title */}
          <CardDescription className="text-muted-foreground">See how you stack up against the competition.</CardDescription> {/* Ensured muted color */}
        </CardHeader>
        <CardContent>
            {/* Filter Controls - Now here */}
            <div className="flex flex-col sm:flex-row gap-4 mb-6"> {/* Increased bottom margin slightly */}
              <div className="flex-1 space-y-1.5"> {/* Added space-y for label consistency */}
                <Label htmlFor="exercise-filter" className="text-sm font-medium">Exercise</Label> {/* Ensured label style */}
                <Select value={exerciseFilter} onValueChange={setExerciseFilter}>
                  <SelectTrigger id="exercise-filter">
                    <SelectValue placeholder="Select Exercise" />
                  </SelectTrigger>
                  <SelectContent>
                    {exerciseOptions.map(option => (
                      <SelectItem key={option} value={option}>{option}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="flex-1 space-y-1.5"> {/* Added space-y for label consistency */}
                <Label htmlFor="scope-filter" className="text-sm font-medium">Scope</Label> {/* Ensured label style */}
                <Select value={scopeFilter} onValueChange={setScopeFilter}>
                  <SelectTrigger id="scope-filter">
                    <SelectValue placeholder="Select Scope" />
                  </SelectTrigger>
                  <SelectContent>
                    {scopeOptions.map(option => (
                      <SelectItem
                        key={option}
                        value={option}
                        disabled={option === scopeOptions[1]} // Disable Local for now
                        className={cn(option === scopeOptions[1] && "text-muted-foreground")} // Indicate disabled state
                      >
                          {option}{option === scopeOptions[1] && " (Coming Soon)"} {/* Add coming soon text */}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <Table>
                <TableCaption className="text-muted-foreground py-4"> {/* Adjusted caption style */}
                    {filteredLeaderboard.length > 0
                        ? "Leaderboard rankings based on selected criteria."
                        : "No data available for the selected filters."
                    }
                    {scopeFilter === scopeOptions[1] && " (Local filtering not yet implemented)"}
                </TableCaption>
                <TableHeader>
                <TableRow className="border-b border-border hover:bg-transparent"> {/* Removed hover effect from header row */}
                    <TableHead className="w-[80px] text-muted-foreground font-medium">Rank</TableHead> {/* Styled header */}
                    <TableHead className="text-muted-foreground font-medium">User</TableHead> {/* Styled header */}
                    <TableHead className="text-right text-muted-foreground font-medium">Score</TableHead> {/* Styled header */}
                </TableRow>
                </TableHeader>
                <TableBody>
                {filteredLeaderboard.length > 0 ? (
                    filteredLeaderboard.map((user) => (
                        // Added hover effect to body rows
                        <TableRow key={`${user.exercise}-${user.rank}-${user.name}`} className="border-b border-border/50 hover:bg-muted/50 transition-colors">
                            <TableCell className="font-semibold text-lg text-primary">{user.rank}</TableCell> {/* Kept rank prominent */}
                            <TableCell>
                                <div className="flex items-center space-x-3">
                                    <Avatar className="h-8 w-8"> {/* Slightly smaller avatar */}
                                        <AvatarImage src={user.avatar || undefined} alt={user.name} />
                                        <AvatarFallback className="bg-muted text-muted-foreground text-xs font-medium"> {/* Consistent fallback style */}
                                            {getInitials(user.name)}
                                        </AvatarFallback>
                                    </Avatar>
                                    <span className="font-medium text-foreground">{user.name}</span>
                                </div>
                            </TableCell>
                            <TableCell className="text-right font-medium text-foreground tabular-nums">{user.score}</TableCell> {/* Ensured consistent font, added tabular-nums */}
                        </TableRow>
                    ))
                ) : (
                    <TableRow>
                        <TableCell colSpan={3} className="text-center text-muted-foreground py-8"> {/* Adjusted padding for empty state */}
                            No rankings found for {exerciseFilter}.
                        </TableCell>
                    </TableRow>
                )}
                </TableBody>
            </Table>
        </CardContent>
      </Card>
    </div>
  );
};

export default Leaderboard; 