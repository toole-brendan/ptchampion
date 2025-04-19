import React, { useMemo, useState, useEffect, useCallback } from 'react';
import { format } from "date-fns";
import { DateRange } from "react-day-picker";
import { Calendar as CalendarIcon, Clock, Repeat, TrendingUp, Dumbbell, Award, ChevronLeft, ChevronRight, Loader2 } from "lucide-react";
import { useQuery } from '@tanstack/react-query';
import { keepPreviousData } from '@tanstack/react-query';

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
import { PaginatedExercisesResponse, ExerciseResponse } from '../lib/types';
import { useAuth } from '../lib/authContext';
import { formatTime, formatDistance } from '../lib/utils';

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

const DEFAULT_PAGE_SIZE = 15;

const History: React.FC = () => {
  const { user, isLoading: isAuthLoading } = useAuth();
  const [page, setPage] = useState(1);
  const [pageSize] = useState(DEFAULT_PAGE_SIZE);
  const [exerciseFilter, setExerciseFilter] = useState<string>('All');
  const [dateRange, setDateRange] = useState<DateRange | undefined>(undefined);

  const { 
    data: paginatedData, 
    isLoading: isLoadingHistory, 
    error: historyError, 
    isFetching,
    refetch
  } = useQuery<PaginatedExercisesResponse, Error>({
    queryKey: ['exerciseHistory', user?.id, page, pageSize],
    queryFn: () => getUserExercises(page, pageSize),
    enabled: !!user,
    placeholderData: keepPreviousData,
    staleTime: 1000 * 60,
  });

  const exercises: ExerciseResponse[] = useMemo(() => paginatedData?.items || [], [paginatedData]);
  const totalCount = useMemo(() => paginatedData?.total_count || 0, [paginatedData]);
  const totalPages = useMemo(() => Math.ceil(totalCount / pageSize), [totalCount, pageSize]);

  const isLoading = isAuthLoading || isLoadingHistory;
  const error = historyError;

  useEffect(() => {
    setPage(1);
  }, [exerciseFilter, dateRange]);

  const dateFilteredHistory = useMemo(() => {
    if (!dateRange?.from && !dateRange?.to) {
      return exercises;
    }
    return exercises.filter((session: ExerciseResponse) => {
      try {
        const sessionDate = new Date(session.created_at);
        const from = dateRange?.from;
        const to = dateRange?.to;
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
        return false;
      }
    });
  }, [exercises, dateRange]);

  const summaryStats = useMemo(() => {
    const totalWorkouts = dateFilteredHistory.length;
    let totalSeconds = 0;
    let totalReps = 0;
    let totalDistance = 0;

    dateFilteredHistory.forEach((session: ExerciseResponse) => {
      if (session.time_in_seconds) {
        totalSeconds += session.time_in_seconds;
      }
      
      if (session.reps) {
        totalReps += session.reps;
      }
      
      if (session.distance) {
        totalDistance += session.distance / 1000;
      }
    });

    return {
      totalWorkouts,
      totalTime: formatTime(totalSeconds),
      totalReps,
      totalDistance: totalDistance.toFixed(1),
    };
  }, [dateFilteredHistory]);

  const exerciseTypes = useMemo(() => {
    const types = new Set(dateFilteredHistory.map((session: ExerciseResponse) => session.exercise_type));
    return ['All', ...Array.from(types).sort()];
  }, [dateFilteredHistory]);

  useEffect(() => {
    if (!exerciseTypes.includes(exerciseFilter)) {
      setExerciseFilter('All');
    }
  }, [exerciseTypes, exerciseFilter]);

  const filteredHistory = useMemo(() => {
    if (exerciseFilter === 'All') {
      return dateFilteredHistory;
    }
    return dateFilteredHistory.filter((session: ExerciseResponse) => session.exercise_type === exerciseFilter);
  }, [dateFilteredHistory, exerciseFilter]);

  const { chartData, metricName, yAxisLabel } = useMemo(() => {
    if (exerciseFilter === 'All') {
      return { chartData: [], metricName: '', yAxisLabel: '' };
    }
    const { metric, unit } = getExerciseMetric(exerciseFilter);
    if (!metric) {
      return { chartData: [], metricName: '', yAxisLabel: '' };
    }
    const data = dateFilteredHistory
      .filter((session: ExerciseResponse) => session.exercise_type === exerciseFilter)
      .map(session => {
        let value;
        if (metric === 'reps') {
          value = session.reps;
        } else if (metric === 'distance' && session.distance) {
          value = session.distance / 1000;
        }
        return { date: session.created_at.split('T')[0], value };
      })
      .filter(item => item.value !== null && item.value !== undefined)
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    const name = `${exerciseFilter} ${unit}`;
    const yLabel = unit === 'km' ? `Distance (${unit})` : unit;
    return { chartData: data, metricName: name, yAxisLabel: yLabel };
  }, [dateFilteredHistory, exerciseFilter]);

  const personalBests = useMemo(() => {
    const bests: { [key: string]: { exercise: string, metric: string, value: number | string, date: string } } = {};
    dateFilteredHistory.forEach((session: ExerciseResponse) => {
      const { metric, unit } = getExerciseMetric(session.exercise_type);
      if (!metric) return;
      
      let currentValue: number | undefined;
      let formattedValue: string | number;
      
      if (metric === 'reps') {
        currentValue = session.reps;
        formattedValue = currentValue || 0;
      } else if (metric === 'distance' && session.distance) {
        currentValue = session.distance / 1000;
        formattedValue = `${currentValue.toFixed(2)} ${unit}`;
      } else {
        return;
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

  if (isLoading && !paginatedData) {
    return (
      <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
        <div className="text-center text-muted-foreground">
          <Loader2 className="mx-auto mb-2 size-8 animate-spin"/>
          <p className="text-lg">Loading history...</p>
        </div>
      </div>
    );
  }

  if (error && !isFetching) {
    return (
      <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
        <Card className="w-full max-w-md border-destructive/50 bg-destructive/10">
          <CardHeader>
            <CardTitle className="text-center text-destructive">Error Loading History</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 text-center">
            <p className="text-sm text-destructive">{error instanceof Error ? error.message : String(error)}</p>
            <Button onClick={() => refetch()} variant="destructive">
              Try Again
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!isLoading && totalCount === 0) {
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
    <div className={cn("space-y-6", isFetching && "opacity-75 transition-opacity duration-300")}>
      <h1 className="text-2xl font-semibold text-foreground">Training History</h1>

      <Card>
        <CardContent className="flex flex-col gap-3 pt-6 sm:flex-row">
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
                <CalendarIcon className="mr-2 size-4" />
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

          <div className="w-full grow sm:w-auto sm:max-w-[240px]">
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
                  <stat.icon className="size-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                  <div className="text-2xl font-bold text-foreground">{stat.value} <span className="text-sm font-normal text-muted-foreground">{stat.unit}</span></div>
              </CardContent>
          </Card>
        ))}
      </div>

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
            <div className="flex h-[300px] items-center justify-center p-4 text-center text-sm text-muted-foreground">
              {exerciseFilter === 'All'
                ? 'Select an exercise filter above to display its trend chart.'
                : `Not enough data points (minimum 2 required) for ${exerciseFilter} to display a trend chart.`}
            </div>
          )}
        </CardContent>
      </Card>

      <Card className="transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="flex items-center text-lg font-semibold">
            <Award className="mr-2 size-5 text-yellow-500" /> Personal Bests
          </CardTitle>
          <CardDescription>Your top performance records based on current filters.</CardDescription>
        </CardHeader>
        <CardContent>
          {personalBests.length > 0 ? (
            <ul className="space-y-2">
              {personalBests.map((pb, index) => (
                <li key={index} className="flex items-center justify-between rounded-md bg-muted/50 p-3 text-sm transition-colors hover:bg-muted">
                  <div className="flex items-center gap-2">
                     <span className="font-medium capitalize text-foreground">{pb.exercise}</span>
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
            <p className="py-4 text-center text-sm text-muted-foreground">
              No personal bests found for the selected filters.
            </p>
          )}
        </CardContent>
      </Card>

      <Card className="overflow-hidden transition-shadow hover:shadow-md">
        <CardHeader>
          <CardTitle className="text-lg font-semibold">Filtered Sessions</CardTitle>
          <CardDescription> Detailed log of workouts matching your filters. </CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-b border-border/50 hover:bg-transparent">
                <TableHead className="w-[130px] text-xs font-medium uppercase tracking-wider text-muted-foreground">Exercise</TableHead>
                <TableHead className="text-xs font-medium uppercase tracking-wider text-muted-foreground">Date</TableHead>
                <TableHead className="text-xs font-medium uppercase tracking-wider text-muted-foreground">Duration</TableHead>
                <TableHead className="text-right text-xs font-medium uppercase tracking-wider text-muted-foreground">Performance</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredHistory.length > 0 ? (
                filteredHistory.map((session) => (
                  <TableRow key={session.id} className="text-sm transition-colors hover:bg-muted/50">
                    <TableCell className="font-medium capitalize text-foreground">{session.exercise_type}</TableCell>
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
                  <TableCell colSpan={4} className="h-24 text-center text-sm text-muted-foreground">
                    {exercises.length > 0 
                      ? "No sessions found matching your current filters."
                      : "Loading sessions..."}
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
          
           <div className="flex items-center justify-between border-t border-border/50 p-4">
              <div className="text-sm text-muted-foreground">
                Page {page} of {totalPages} ({totalCount} total records)
              </div>
              <div className="space-x-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setPage(prev => Math.max(prev - 1, 1))}
                  disabled={page <= 1 || isFetching}
                >
                  <ChevronLeft className="mr-1 size-4" /> Previous
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setPage(prev => Math.min(prev + 1, totalPages))}
                  disabled={page >= totalPages || isFetching}
                >
                  Next <ChevronRight className="ml-1 size-4" />
                </Button>
              </div>
            </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default History; 