import React from 'react';
import { format, subDays, startOfWeek, endOfWeek, startOfMonth, endOfMonth, startOfYear, endOfYear } from 'date-fns';
import { Calendar as CalendarIcon, Filter, X } from 'lucide-react';

import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

export type DateRange = {
  from: Date;
  to?: Date;
};

interface HistoryFilterBarProps {
  exerciseFilter: string;
  dateRange: DateRange | undefined;
  exerciseTypes: string[];
  onExerciseFilterChange: (value: string) => void;
  onDateRangeChange: (value: DateRange | undefined) => void;
  onClearFilters: () => void;
}

export const HistoryFilterBar: React.FC<HistoryFilterBarProps> = ({
  exerciseFilter,
  dateRange,
  exerciseTypes,
  onExerciseFilterChange,
  onDateRangeChange,
  onClearFilters,
}) => {
  const currentDate = new Date();
  
  // Preset date range handlers
  const setWeekRange = () => {
    const startDay = startOfWeek(currentDate, { weekStartsOn: 1 }); // Start on Monday
    const endDay = endOfWeek(currentDate, { weekStartsOn: 1 });
    onDateRangeChange({ from: startDay, to: endDay });
  };
  
  const setMonthRange = () => {
    const startDay = startOfMonth(currentDate);
    const endDay = endOfMonth(currentDate);
    onDateRangeChange({ from: startDay, to: endDay });
  };
  
  const setYearRange = () => {
    const startDay = startOfYear(currentDate);
    const endDay = endOfYear(currentDate);
    onDateRangeChange({ from: startDay, to: endDay });
  };
  
  const isCustomRange = dateRange && !(
    // Not week range
    (dateRange.from.getTime() === startOfWeek(currentDate, { weekStartsOn: 1 }).getTime() &&
     dateRange.to?.getTime() === endOfWeek(currentDate, { weekStartsOn: 1 }).getTime()) ||
    // Not month range
    (dateRange.from.getTime() === startOfMonth(currentDate).getTime() &&
     dateRange.to?.getTime() === endOfMonth(currentDate).getTime()) ||
    // Not year range
    (dateRange.from.getTime() === startOfYear(currentDate).getTime() &&
     dateRange.to?.getTime() === endOfYear(currentDate).getTime())
  );

  return (
    <div className="space-y-4">
      {/* Time period tabs */}
      <div className="flex w-full items-center justify-between border-b border-olive-mist/20 font-medium">
        <nav className="flex flex-1 items-center">
          <Button
            variant="link"
            className={cn(
              "pb-3 text-sm font-medium uppercase tracking-wider",
              !dateRange 
                ? "border-b-2 border-brass-gold text-brass-gold" 
                : "text-muted-foreground"
            )}
            onClick={() => onDateRangeChange(undefined)}
          >
            All Time
          </Button>
          <Button
            variant="link"
            className={cn(
              "pb-3 text-sm font-medium uppercase tracking-wider",
              dateRange?.from?.getTime() === startOfWeek(currentDate, { weekStartsOn: 1 }).getTime() &&
              dateRange?.to?.getTime() === endOfWeek(currentDate, { weekStartsOn: 1 }).getTime()
                ? "border-b-2 border-brass-gold text-brass-gold" 
                : "text-muted-foreground"
            )}
            onClick={setWeekRange}
          >
            This Week
          </Button>
          <Button
            variant="link"
            className={cn(
              "pb-3 text-sm font-medium uppercase tracking-wider",
              dateRange?.from?.getTime() === startOfMonth(currentDate).getTime() &&
              dateRange?.to?.getTime() === endOfMonth(currentDate).getTime()
                ? "border-b-2 border-brass-gold text-brass-gold" 
                : "text-muted-foreground"
            )}
            onClick={setMonthRange}
          >
            This Month
          </Button>
          <Button
            variant="link"
            className={cn(
              "pb-3 text-sm font-medium uppercase tracking-wider",
              dateRange?.from?.getTime() === startOfYear(currentDate).getTime() &&
              dateRange?.to?.getTime() === endOfYear(currentDate).getTime()
                ? "border-b-2 border-brass-gold text-brass-gold" 
                : "text-muted-foreground"
            )}
            onClick={setYearRange}
          >
            This Year
          </Button>
        </nav>
      </div>
      
      <div className="flex flex-col gap-4 sm:flex-row">
        {/* Custom date range picker */}
        <div className="space-y-2 sm:w-1/2">
          <label className="font-semibold text-sm uppercase tracking-wide text-tactical-gray">Custom Date Range</label>
          <Popover>
            <PopoverTrigger asChild>
              <Button
                id="date"
                variant={"outline"}
                className={cn(
                  "w-full justify-start text-left font-normal bg-cream border-army-tan/30",
                  !isCustomRange && "text-tactical-gray"
                )}
              >
                <CalendarIcon className="mr-2 size-4" />
                {isCustomRange && dateRange?.from ? (
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
                  <span>Pick a custom range</span>
                )}
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto p-0" align="start">
              <Calendar
                initialFocus
                mode="range"
                defaultMonth={dateRange?.from}
                selected={isCustomRange ? dateRange : undefined}
                onSelect={onDateRangeChange}
                numberOfMonths={2}
              />
            </PopoverContent>
          </Popover>
        </div>

        {/* Exercise type filter */}
        <div className="space-y-2 sm:w-1/2">
          <label className="font-semibold text-sm uppercase tracking-wide text-tactical-gray">Exercise Type</label>
          <Select value={exerciseFilter} onValueChange={onExerciseFilterChange}>
            <SelectTrigger className="border-army-tan/30 w-full bg-cream">
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
      
      {/* Clear filters button */}
      {(dateRange || exerciseFilter !== 'All') && (
        <Button 
          variant="outline" 
          onClick={onClearFilters}
          className="hover:bg-brass-gold/10 w-full border-brass-gold text-brass-gold"
        >
          <X className="mr-2 size-4" /> CLEAR FILTERS
        </Button>
      )}
    </div>
  );
};

export default HistoryFilterBar; 