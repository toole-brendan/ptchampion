import React, { useMemo, useState, useEffect } from 'react';
import { format } from "date-fns";
import { Calendar as CalendarIcon, Clock, Repeat, TrendingUp, Dumbbell, Award, ChevronLeft, ChevronRight, Loader2, History as HistoryIcon } from "lucide-react";
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
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { getUserExercises } from '../lib/apiClient';
import { ExerciseResponse } from '../lib/types';
import { useAuth } from '../lib/authContext';
import { formatTime, formatDistance } from '../lib/utils';

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
    <div className="absolute left-0 top-0 h-px w-[15px] origin-top-left rotate-45 bg-tactical-gray/50"></div>
    <div className="absolute right-0 top-0 h-px w-[15px] origin-top-right -rotate-45 bg-tactical-gray/50"></div>
    <div className="absolute bottom-0 left-0 h-px w-[15px] origin-bottom-left -rotate-45 bg-tactical-gray/50"></div>
    <div className="absolute bottom-0 right-0 h-px w-[15px] origin-bottom-right rotate-45 bg-tactical-gray/50"></div>
  </>
);

// Header divider component
const HeaderDivider: React.FC = () => (
  <div className="mx-auto my-2 h-px w-16 bg-brass-gold"></div>
);

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
        <div className="text-center">
          <Loader2 className="mx-auto mb-4 size-10 animate-spin text-brass-gold"/>
          <p className="font-heading text-lg uppercase">Loading history...</p>
        </div>
      </div>
    );
  }

  if (error && !isFetching) {
    return (
      <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
        <div className="bg-card-background relative w-full max-w-md overflow-hidden rounded-card shadow-medium">
          <MilitaryCorners />
          <div className="p-content">
            <div className="mb-4 text-center">
              <h2 className="font-heading text-heading3 uppercase tracking-wider text-error">
                Error Loading History
              </h2>
              <HeaderDivider />
            </div>
            <div className="space-y-4 text-center">
              <p className="text-sm text-tactical-gray">{error instanceof Error ? error.message : String(error)}</p>
              <Button 
                onClick={() => refetch()} 
                variant="outline"
                className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
              >
                TRY AGAIN
              </Button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!isLoading && totalCount === 0) {
    return (
      <div className="space-y-section">
        <div className="bg-card-background relative overflow-hidden rounded-card p-content shadow-medium">
          <MilitaryCorners />
          <div className="mb-4 text-center">
            <h2 className="font-heading text-heading3 uppercase tracking-wider text-command-black">
              Training History
            </h2>
            <HeaderDivider />
            <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">Track your progress over time</p>
          </div>
        </div>
        
        <div className="bg-card-background relative overflow-hidden rounded-card text-center shadow-medium">
          <MilitaryCorners />
          <div className="p-content">
            <h3 className="mb-4 font-heading text-heading4 uppercase tracking-wider">No Workouts Found</h3>
            <p className="text-tactical-gray">You haven't logged any exercises yet.</p>
            <p className="mt-2 text-tactical-gray">Start tracking your workouts to see your progress here!</p>
          </div>
        </div>
      </div>
    );
  }
  
  return (
    <div className={cn("space-y-section", isFetching && "opacity-75 transition-opacity duration-300")}>
      <div className="bg-card-background relative overflow-hidden rounded-card p-content shadow-medium">
        <MilitaryCorners />
        <div className="mb-4 text-center">
          <h2 className="font-heading text-heading3 uppercase tracking-wider text-command-black">
            Training History
          </h2>
          <HeaderDivider />
          <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">Track your progress over time</p>
        </div>
      </div>

      <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
        <MilitaryCorners />
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center">
            <HistoryIcon className="mr-2 size-5 text-brass-gold" />
            <h2 className="font-heading text-heading4 uppercase tracking-wider text-cream">
              Filter Workouts
            </h2>
          </div>
        </div>
        <div className="p-content">
          <div className="mb-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <label className="font-semibold text-sm uppercase tracking-wide text-tactical-gray">Date Range</label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    id="date"
                    variant={"outline"}
                    className={cn(
                      "w-full justify-start text-left font-normal bg-cream border-army-tan/30",
                      !dateRange && "text-tactical-gray"
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
            </div>

            <div className="space-y-2">
              <label className="font-semibold text-sm uppercase tracking-wide text-tactical-gray">Exercise Type</label>
              <Select value={exerciseFilter} onValueChange={setExerciseFilter}>
                <SelectTrigger className="w-full border-army-tan/30 bg-cream">
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
          </div>
          
          {(dateRange || exerciseFilter !== 'All') && (
            <Button 
              variant="outline" 
              onClick={() => { setDateRange(undefined); setExerciseFilter('All'); }} 
              className="w-full border-brass-gold text-brass-gold hover:bg-brass-gold/10"
            >
              CLEAR FILTERS
            </Button>
          )}
        </div>
      </div>

      <div className="grid gap-card-gap md:grid-cols-2 lg:grid-cols-4">
        {[
          { title: 'TOTAL WORKOUTS', value: summaryStats.totalWorkouts, icon: Dumbbell, unit: '' },
          { title: 'TOTAL TIME', value: summaryStats.totalTime, icon: Clock, unit: '' },
          { title: 'TOTAL REPS', value: summaryStats.totalReps, icon: Repeat, unit: '' },
          { title: 'TOTAL DISTANCE', value: summaryStats.totalDistance, icon: TrendingUp, unit: 'km' },
        ].map((stat, index) => (
          <div key={index} className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
            <MilitaryCorners />
            <div className="p-content">
              <div className="flex flex-row items-center justify-between space-y-0 pb-2">
                <div className="font-semibold text-xs uppercase tracking-wider text-tactical-gray">{stat.title}</div>
                <stat.icon className="size-5 text-brass-gold" />
              </div>
              <div className="font-heading text-heading3 text-command-black">
                {stat.value} {stat.unit && <span className="font-semibold text-sm text-tactical-gray">{stat.unit}</span>}
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
        <MilitaryCorners />
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center">
            <TrendingUp className="mr-2 size-5 text-brass-gold" />
            <h2 className="font-heading text-heading4 uppercase tracking-wider text-cream">
              {exerciseFilter === 'All' ? 'Performance Trend' : `${exerciseFilter} Trend`}
            </h2>
          </div>
          <p className="text-sm text-army-tan">
            {exerciseFilter === 'All'
              ? 'Select an exercise filter to visualize its trend over time.'
              : `Performance trend for ${exerciseFilter.toLowerCase()}.`}
          </p>
        </div>
        <div className="p-content">
          {exerciseFilter !== 'All' && chartData.length > 1 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={chartData} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--color-olive-mist)" opacity={0.3} />
                <XAxis dataKey="date" stroke="var(--color-tactical-gray)" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis
                  stroke="var(--color-tactical-gray)" fontSize={11} tickLine={false} axisLine={false}
                  allowDecimals={yAxisLabel.includes('km')}
                  width={40}
                  label={{ value: yAxisLabel, angle: -90, position: 'insideLeft', offset: 0, style: { textAnchor: 'middle', fontSize: '11px', fill: 'var(--color-tactical-gray)' } }}
                />
                <Tooltip
                    contentStyle={{ backgroundColor: 'var(--color-cream)', border: '1px solid var(--color-army-tan)', borderRadius: 'var(--radius-card)', fontSize: '12px' }}
                    cursor={{ stroke: 'var(--color-brass-gold)' , strokeWidth: 1, strokeDasharray: '3 3' }}
                    formatter={(value: number) => [`${value} ${yAxisLabel.includes('km') ? 'km' : (yAxisLabel || '')}`, metricName.replace(exerciseFilter + ' ', '')]}
                    labelFormatter={(label: string) => `Date: ${format(new Date(label), 'PP')}`}
                />
                <Line
                  type="monotone" dataKey="value" name={metricName}
                  stroke="var(--color-brass-gold)" strokeWidth={2}
                  activeDot={{ r: 6, fill: 'var(--color-brass-gold)', stroke: 'var(--color-cream)', strokeWidth: 2 }}
                  dot={{ r: 3, fill: 'var(--color-brass-gold)', strokeWidth: 0 }}
                  connectNulls
                 />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex h-[300px] items-center justify-center p-4 text-center font-semibold text-sm text-tactical-gray">
              {exerciseFilter === 'All'
                ? 'Select an exercise filter above to display its trend chart.'
                : `Not enough data points (minimum 2 required) for ${exerciseFilter} to display a trend chart.`}
            </div>
          )}
        </div>
      </div>

      <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
        <MilitaryCorners />
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center">
            <Award className="mr-2 size-5 text-brass-gold" />
            <h2 className="font-heading text-heading4 uppercase tracking-wider text-cream">
              Personal Records
            </h2>
          </div>
          <p className="text-sm text-army-tan">
            Your top performance records based on current filters.
          </p>
        </div>
        <div className="p-content">
          {personalBests.length > 0 ? (
            <ul className="space-y-3">
              {personalBests.map((pb, index) => (
                <li key={index} className="relative overflow-hidden rounded-card border-l-4 border-brass-gold bg-cream/30 p-3 shadow-small">
                  <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
                  <div className="flex items-center justify-between">
                    <div className="flex flex-col">
                      <span className="font-heading text-sm uppercase text-command-black">{pb.exercise}</span>
                      <span className="font-semibold text-xs text-tactical-gray">{pb.metric}</span>
                    </div>
                    <div className="text-right">
                      <p className="font-heading text-xl text-brass-gold">{pb.value}</p>
                      <p className="text-xs text-tactical-gray">on {pb.date}</p>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <p className="py-4 text-center font-semibold text-sm text-tactical-gray">
              No personal bests found for the selected filters.
            </p>
          )}
        </div>
      </div>

      <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
        <MilitaryCorners />
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center">
            <HistoryIcon className="mr-2 size-5 text-brass-gold" />
            <h2 className="font-heading text-heading4 uppercase tracking-wider text-cream">
              Workout History
            </h2>
          </div>
          <p className="text-sm text-army-tan">
            Detailed log of workouts matching your filters.
          </p>
        </div>
        <div className="p-content">
          <div className="overflow-hidden rounded-card border border-olive-mist/20">
            <Table>
              <TableHeader>
                <TableRow className="bg-tactical-gray/10 hover:bg-transparent">
                  <TableHead className="w-[130px] font-heading text-xs uppercase tracking-wider text-tactical-gray">Exercise</TableHead>
                  <TableHead className="font-heading text-xs uppercase tracking-wider text-tactical-gray">Date</TableHead>
                  <TableHead className="font-heading text-xs uppercase tracking-wider text-tactical-gray">Duration</TableHead>
                  <TableHead className="text-right font-heading text-xs uppercase tracking-wider text-tactical-gray">Performance</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredHistory.length > 0 ? (
                  filteredHistory.map((session) => (
                    <TableRow key={session.id} className="border-b border-olive-mist/10 text-sm transition-colors hover:bg-brass-gold/5">
                      <TableCell className="font-semibold uppercase text-command-black">{session.exercise_type}</TableCell>
                      <TableCell className="text-tactical-gray">{format(new Date(session.created_at), "PP p")}</TableCell>
                      <TableCell className="text-tactical-gray">{session.time_in_seconds ? formatTime(session.time_in_seconds) : '-'}</TableCell>
                      <TableCell className="text-right font-heading text-brass-gold">
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
                    <TableCell colSpan={4} className="h-24 text-center font-semibold text-sm text-tactical-gray">
                      {exercises.length > 0 
                        ? "No sessions found matching your current filters."
                        : "Loading sessions..."}
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
          
          <div className="mt-4 flex items-center justify-between">
            <div className="text-sm text-tactical-gray">
              Page {page} of {totalPages} ({totalCount} total records)
            </div>
            <div className="space-x-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage(prev => Math.max(prev - 1, 1))}
                disabled={page <= 1 || isFetching}
                className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
              >
                <ChevronLeft className="mr-1 size-4" /> PREV
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage(prev => Math.min(prev + 1, totalPages))}
                disabled={page >= totalPages || isFetching}
                className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
              >
                NEXT <ChevronRight className="ml-1 size-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default History; 