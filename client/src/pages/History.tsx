import React, { useMemo, useState, useEffect, useCallback } from 'react';
import { format } from "date-fns";
import { DateRange } from "react-day-picker";
import { Calendar as CalendarIcon, Clock, Repeat, TrendingUp, Dumbbell, Award } from "lucide-react";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { getUserExercises } from '../lib/apiClient';
import { ExerciseResponse } from '../lib/types';
import { useAuth } from '../lib/authContext';
import { formatTime, formatDistance } from '../lib/utils';
import config from '../lib/config';

// Helper to determine metric and unit for an exercise
const getExerciseMetric = (exercise: string): { metric: 'reps' | 'distance' | null, unit: string } => {
  switch (exercise.toLowerCase()) {
    case 'push-ups':
    case 'sit-ups':
    case 'pull-ups':
      return { metric: 'reps', unit: 'Reps' };
    case 'running':
    case '2-mile run':
      return { metric: 'distance', unit: 'km' };
    // Add more cases for other exercises if needed
    default:
      return { metric: null, unit: '' };
  }
};

const History: React.FC = () => {
  const { user } = useAuth();
  const [exercises, setExercises] = useState<ExerciseResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [exerciseFilter, setExerciseFilter] = useState<string>('All');
  const [dateRange, setDateRange] = useState<DateRange | undefined>(undefined);

  // Function to fetch exercise history
  const fetchExerciseHistory = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      console.log("Fetching exercise history...");
      // Also log auth state to help debug
      console.log("Auth state when fetching:", { user, isAuthenticated: !!user });
      
      const data = await getUserExercises();
      console.log("Exercise history fetched successfully:", data);
      setExercises(data || []); // Ensure we always set an array even if null is returned
    } catch (err) {
      console.error("Error fetching exercise history:", err);
      
      // Check if it's an authentication error
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch exercise history';
      if (errorMessage.includes('Authentication required') || 
          errorMessage.includes('Unauthorized') || 
          errorMessage.includes('401')) {
        setError(`Authentication error: ${errorMessage}. Try logging out and back in.`);  
      } else {
        setError(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  }, [user]);
  
  // Initial fetch
  useEffect(() => {
    if (user) { // Only fetch if we have a user
      // Add a small delay before first fetch to allow port discovery to complete
      const initialFetchTimeout = setTimeout(() => {
        fetchExerciseHistory();
      }, 500); // 500ms should be enough to allow port discovery
      
      // Cleanup on unmount
      return () => clearTimeout(initialFetchTimeout);
    } else {
      setLoading(false);
      setError("You must be logged in to view your exercise history.");
    }
  }, [fetchExerciseHistory, user]);

  // ----- ALWAYS CALCULATE THESE MEMOIZED VALUES, REGARDLESS OF LOADING/ERROR STATE -----
  
  // Filtered Data Source based on Date Range
  const dateFilteredHistory = useMemo(() => {
    if (!dateRange?.from && !dateRange?.to) {
      return exercises; // No date filter applied
    }
    return exercises.filter(session => {
      try {
        const sessionDate = new Date(session.created_at);
        const from = dateRange?.from;
        const to = dateRange?.to;
        // Set time to 00:00:00 for from date and 23:59:59 for to date for inclusive range
        const startOfDayFrom = from ? new Date(from.setHours(0, 0, 0, 0)) : null;
        const endOfDayTo = to ? new Date(to.setHours(23, 59, 59, 999)) : null;

        if (startOfDayFrom && endOfDayTo) {
          return sessionDate >= startOfDayFrom && sessionDate <= endOfDayTo;
        } else if (startOfDayFrom) {
          return sessionDate >= startOfDayFrom;
        } else if (endOfDayTo) {
          return sessionDate <= endOfDayTo;
        }
        return true;
      } catch (e) {
        console.error("Error parsing date:", session.created_at, e);
        return false; // Exclude if date format is invalid
      }
    });
  }, [exercises, dateRange]);

  // Recalculate summary stats based on date-filtered data
  const summaryStats = useMemo(() => {
    let totalWorkouts = dateFilteredHistory.length;
    let totalSeconds = 0;
    let totalReps = 0;
    let totalDistance = 0;

    dateFilteredHistory.forEach(session => {
      if (session.time_in_seconds) {
        totalSeconds += session.time_in_seconds;
      }
      
      if (session.reps) {
        totalReps += session.reps;
      }
      
      if (session.distance) {
        totalDistance += session.distance / 1000; // Convert meters to km
      }
    });

    return {
      totalWorkouts,
      totalTime: formatTime(totalSeconds),
      totalReps,
      totalDistance: totalDistance.toFixed(1),
    };
  }, [dateFilteredHistory]);

  // Update exerciseTypes based on date-filtered data
  const exerciseTypes = useMemo(() => {
    const types = new Set(dateFilteredHistory.map(session => session.exercise_type));
    return ['All', ...Array.from(types).sort()];
  }, [dateFilteredHistory]);

  // Reset exercise filter if the selected exercise is no longer in the filtered list
  useEffect(() => {
    if (!exerciseTypes.includes(exerciseFilter)) {
      setExerciseFilter('All');
    }
  }, [exerciseTypes, exerciseFilter]);

  // Filter history table based on exercise and date
  const filteredHistory = useMemo(() => {
    if (exerciseFilter === 'All') {
      return dateFilteredHistory;
    }
    return dateFilteredHistory.filter(session => session.exercise_type === exerciseFilter);
  }, [dateFilteredHistory, exerciseFilter]);

  // Prepare chart data based on exercise and date
  const { chartData, metricName, yAxisLabel } = useMemo(() => {
    if (exerciseFilter === 'All') {
      return { chartData: [], metricName: '', yAxisLabel: '' };
    }
    const { metric, unit } = getExerciseMetric(exerciseFilter);
    if (!metric) {
      return { chartData: [], metricName: '', yAxisLabel: '' };
    }
    const data = dateFilteredHistory
      .filter(session => session.exercise_type === exerciseFilter)
      .map(session => {
        let value;
        if (metric === 'reps') {
          value = session.reps;
        } else if (metric === 'distance' && session.distance) {
          value = session.distance / 1000; // Convert meters to km
        }
        return { date: session.created_at.split('T')[0], value };
      })
      .filter(item => item.value !== null && item.value !== undefined)
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    const name = `${exerciseFilter} ${unit}`;
    const yLabel = unit === 'km' ? `Distance (${unit})` : unit;
    return { chartData: data, metricName: name, yAxisLabel: yLabel };
  }, [dateFilteredHistory, exerciseFilter]);

  // Calculate Personal Bests based on exercise and date
  const personalBests = useMemo(() => {
    const bests: { [key: string]: { exercise: string, metric: string, value: number | string, date: string } } = {};
    dateFilteredHistory.forEach(session => {
      const { metric, unit } = getExerciseMetric(session.exercise_type);
      if (!metric) return;
      
      let currentValue: number | undefined;
      let formattedValue: string | number;
      
      if (metric === 'reps') {
        currentValue = session.reps;
        formattedValue = currentValue || 0;
      } else if (metric === 'distance' && session.distance) {
        currentValue = session.distance / 1000; // Convert meters to km
        formattedValue = `${currentValue.toFixed(2)} ${unit}`;
      } else {
        return; // Skip if no valid value
      }
      
      if (currentValue === undefined) return;
      
      if (!bests[session.exercise_type] ||
          (typeof currentValue === 'number' && 
           typeof bests[session.exercise_type].value === 'number' && 
           currentValue > (bests[session.exercise_type].value as number)) ||
          (typeof currentValue === 'number' && 
           typeof bests[session.exercise_type].value === 'string' && 
           currentValue > parseFloat(bests[session.exercise_type].value as string))
         ) {
        bests[session.exercise_type] = {
          exercise: session.exercise_type,
          metric: metric === 'reps' ? 'Max Reps' : 'Max Distance',
          value: formattedValue,
          date: session.created_at.split('T')[0],
        };
      }
    });
    return Object.values(bests).sort((a,b) => a.exercise.localeCompare(b.exercise));
  }, [dateFilteredHistory]);

  // NOW HANDLE RENDERING STATES
  
  // Show loading state
  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-[calc(100vh-200px)]">
        <div className="text-center text-muted-foreground">
          <p className="text-lg">Loading history...</p>
        </div>
      </div>
    );
  }

  // Show error state if there's an error
  if (error) {
    return (
      <div className="flex justify-center items-center min-h-[calc(100vh-200px)]">
        <Card className="w-full max-w-md border-destructive/50 bg-destructive/10">
          <CardHeader>
            <CardTitle className="text-destructive text-center">Error Loading History</CardTitle>
          </CardHeader>
          <CardContent className="text-center space-y-4">
            <p className="text-sm text-destructive">{error}</p>
            <Button onClick={fetchExerciseHistory} variant="destructive">
              Try Again
            </Button>
            <Button
              variant="secondary"
              onClick={() => {
                // MOCK DATA FOR DEV
                setExercises([
                  { id: 1, user_id: 1, exercise_id: 1, exercise_name: 'Push-ups', exercise_type: 'Push-ups', reps: 30, distance: undefined, time_in_seconds: 45, notes: 'Good form', grade: 85, created_at: '2024-03-28T10:30:00Z'},
                  { id: 2, user_id: 1, exercise_id: 4, exercise_name: 'Running', exercise_type: 'Running', reps: undefined, distance: 5200, time_in_seconds: 1815, notes: 'Morning run', grade: 90, created_at: '2024-03-27T18:00:00Z'},
                  { id: 3, user_id: 1, exercise_id: 2, exercise_name: 'Sit-ups', exercise_type: 'Sit-ups', reps: 55, distance: undefined, time_in_seconds: 70, notes: 'Abdominal workout', grade: 88, created_at: '2024-03-26T11:00:00Z'}
                ]); setError(null); setLoading(false);
              }}
            > Use Demo Data </Button>
            <p className="text-xs text-muted-foreground mt-4">Server: {config.api.baseUrl}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (exercises.length === 0) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-semibold text-foreground">Training History</h1>
        <Card className="text-center">
            <CardHeader>
                <CardTitle>No History Yet</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">You haven't logged any exercises.</p>
              <p className="mt-2 text-muted-foreground">Start tracking your workouts to see your progress here!</p>
            </CardContent>
        </Card>
      </div>
    );
  }
  
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-foreground">Training History</h1>

      {/* Filter Controls Row */}
      <Card>
        <CardContent className="pt-6 flex flex-col sm:flex-row gap-3">
          {/* Date Range Picker */}
          <Popover>
            <PopoverTrigger asChild>
              <Button
                id="date"
                variant={"outline"}
                className={cn(
                  "w-full sm:w-[280px] justify-start text-left font-normal",
                  !dateRange && "text-muted-foreground"
                )}
              >
                <CalendarIcon className="mr-2 h-4 w-4" />
                {dateRange?.from ? (
                  dateRange.to ? (
                    <>
                      {format(dateRange.from, "LLL dd, y")}
                      {" - "}
                      {format(dateRange.to, "LLL dd, y")}
                    </>
                  ) : (
                    format(dateRange.from, "LLL dd, y")
                  )
                ) : (
                  <span>Pick a date range</span>
                )}
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto p-0" align="start">
              <Calendar
                initialFocus
                mode="range"
                defaultMonth={dateRange?.from}
                selected={dateRange}
                onSelect={setDateRange}
                numberOfMonths={2}
              />
            </PopoverContent>
          </Popover>

          {/* Exercise Filter Dropdown */}
          <div className="w-full sm:w-auto sm:max-w-[240px] flex-grow">
              <Select value={exerciseFilter} onValueChange={setExerciseFilter}>
                <SelectTrigger className="w-full">
                  <SelectValue placeholder="Filter by exercise..." />
                </SelectTrigger>
                <SelectContent>
                  {exerciseTypes.map(type => (
                    <SelectItem key={type} value={type}>
                      {type === 'All' ? 'All Exercises' : type}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
          </div>
          {(dateRange || exerciseFilter !== 'All') && (
            <Button variant="ghost" onClick={() => { setDateRange(undefined); setExerciseFilter('All'); }} className="text-muted-foreground">
              Clear Filters
            </Button>
          )}
        </CardContent>
      </Card>

      {/* Summary Stats Section */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {[
          { title: 'Total Workouts', value: summaryStats.totalWorkouts, icon: Dumbbell, unit: '' },
          { title: 'Total Time', value: summaryStats.totalTime, icon: Clock, unit: '' },
          { title: 'Total Reps', value: summaryStats.totalReps, icon: Repeat, unit: '' },
          { title: 'Total Distance', value: summaryStats.totalDistance, icon: TrendingUp, unit: 'km' },
        ].map((stat, index) => (
          <Card key={index} className="transition-shadow hover:shadow-md">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium text-muted-foreground">{stat.title}</CardTitle>
                  <stat.icon className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                  <div className="text-2xl font-bold text-foreground">{stat.value} <span className="text-sm font-normal text-muted-foreground">{stat.unit}</span></div>
              </CardContent>
          </Card>
        ))}
      </div>

      {/* Dynamic Progress Chart Card */}
      <Card className="transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="text-lg font-semibold">
            {exerciseFilter === 'All' ? 'Performance Trend' : `${exerciseFilter} Trend`}
          </CardTitle>
          <CardDescription>
            {exerciseFilter === 'All'
              ? 'Select an exercise filter to visualize its trend over time.'
              : `Performance trend for ${exerciseFilter.toLowerCase()}.`}
          </CardDescription>
        </CardHeader>
        <CardContent className="pl-0 pr-4">
          {exerciseFilter !== 'All' && chartData.length > 1 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={chartData} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border)) / 0.5" />
                <XAxis dataKey="date" stroke="hsl(var(--muted-foreground))" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis
                  stroke="hsl(var(--muted-foreground))" fontSize={11} tickLine={false} axisLine={false}
                  allowDecimals={yAxisLabel.includes('km')}
                  width={40}
                  label={{ value: yAxisLabel, angle: -90, position: 'insideLeft', offset: 0, style: { textAnchor: 'middle', fontSize: '11px', fill: 'hsl(var(--muted-foreground))' } }}
                />
                <Tooltip
                    contentStyle={{ backgroundColor: 'hsl(var(--popover))', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', fontSize: '12px' }}
                    cursor={{ stroke: 'hsl(var(--primary))' , strokeWidth: 1, strokeDasharray: '3 3' }}
                    formatter={(value: number) => [`${value} ${yAxisLabel.includes('km') ? 'km' : (yAxisLabel || '')}`, metricName.replace(exerciseFilter + ' ', '')]}
                    labelFormatter={(label: string) => `Date: ${format(new Date(label), 'PP')}`}
                />
                <Line
                  type="monotone" dataKey="value" name={metricName}
                  stroke="hsl(var(--primary))" strokeWidth={2}
                  activeDot={{ r: 6, fill: 'hsl(var(--primary))', stroke: 'hsl(var(--background))', strokeWidth: 2 }}
                  dot={{ r: 3, fill: 'hsl(var(--primary))', strokeWidth: 0 }}
                  connectNulls
                 />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="text-center text-muted-foreground h-[300px] flex items-center justify-center text-sm p-4">
              {exerciseFilter === 'All'
                ? 'Select an exercise filter above to display its trend chart.'
                : `Not enough data points (minimum 2 required) for ${exerciseFilter} to display a trend chart.`}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Personal Bests Card */}
      <Card className="transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="text-lg font-semibold flex items-center">
            <Award className="h-5 w-5 mr-2 text-yellow-500" /> Personal Bests
          </CardTitle>
          <CardDescription>Your top performance records based on current filters.</CardDescription>
        </CardHeader>
        <CardContent>
          {personalBests.length > 0 ? (
            <ul className="space-y-2">
              {personalBests.map((pb, index) => (
                <li key={index} className="flex items-center justify-between p-3 bg-muted/50 rounded-md text-sm transition-colors hover:bg-muted">
                  <div className="flex items-center gap-2">
                     <span className="font-medium text-foreground capitalize">{pb.exercise}</span>
                     <span className="text-xs text-muted-foreground">({pb.metric})</span>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-primary">{pb.value}</p>
                    <p className="text-xs text-muted-foreground">on {pb.date}</p>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-center text-sm text-muted-foreground py-4">
              No personal bests found for the selected filters.
            </p>
          )}
        </CardContent>
      </Card>

      {/* History Table Card */}
      <Card className="overflow-hidden transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="text-lg font-semibold">Filtered Sessions</CardTitle>
          <CardDescription> Detailed log of workouts matching your filters. </CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-b border-border/50 hover:bg-transparent">
                <TableHead className="w-[130px] text-xs font-medium text-muted-foreground uppercase tracking-wider">Exercise</TableHead>
                <TableHead className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Date</TableHead>
                <TableHead className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Duration</TableHead>
                <TableHead className="text-right text-xs font-medium text-muted-foreground uppercase tracking-wider">Performance</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredHistory.length > 0 ? (
                filteredHistory.map((session) => (
                  <TableRow key={session.id} className="text-sm hover:bg-muted/50 transition-colors">
                    <TableCell className="font-medium text-foreground capitalize">{session.exercise_type}</TableCell>
                    <TableCell className="text-muted-foreground">{format(new Date(session.created_at), "PP p")}</TableCell>
                    <TableCell className="text-muted-foreground">{session.time_in_seconds ? formatTime(session.time_in_seconds) : '-'}</TableCell>
                    <TableCell className="text-right font-medium text-foreground">
                      {session.reps !== undefined && session.reps !== null
                        ? `${session.reps} reps`
                        : session.distance !== undefined && session.distance !== null
                          ? formatDistance(session.distance)
                          : '-'}
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={4} className="text-center text-muted-foreground h-24 text-sm">
                    No sessions found matching your current filters.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
           {filteredHistory.length > 0 && (
             <div className="text-xs text-muted-foreground text-center py-3 px-6 border-t border-border/50">
                {`Showing ${filteredHistory.length} workout${filteredHistory.length === 1 ? '' : 's'} ${dateRange?.from ? `from ${format(dateRange.from, "PP")}` : ''} ${dateRange?.to ? `to ${format(dateRange.to, "PP")}` : ''} ${exerciseFilter !== 'All' ? ` for ${exerciseFilter}` : ''}.`}
             </div>
           )}
        </CardContent>
      </Card>
    </div>
  );
};

export default History; 