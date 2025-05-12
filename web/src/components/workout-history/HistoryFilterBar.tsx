import React from 'react';
import { format } from "date-fns";
import { Calendar as CalendarIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";
import { DateRange as DayPickerDateRange } from 'react-day-picker';

// Export DateRange type for use in parent components
export type DateRange = DayPickerDateRange;

interface HistoryFilterBarProps {
  exerciseFilter: string;
  dateRange: DateRange | undefined;
  exerciseTypes: string[];
  onExerciseFilterChange: (value: string) => void;
  onDateRangeChange: (range: DateRange | undefined) => void;
  onClearFilters: () => void;
}

const HistoryFilterBar: React.FC<HistoryFilterBarProps> = ({
  exerciseFilter,
  dateRange,
  exerciseTypes,
  onExerciseFilterChange,
  onDateRangeChange,
  onClearFilters
}) => {
  const filtersActive = exerciseFilter !== 'All' || !!dateRange;
  
  return (
    <div className="mb-4">
      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="min-w-[140px] space-y-2">
          <Label htmlFor="date-range" className="font-semibold text-xs uppercase tracking-wide text-tactical-gray">Date Range</Label>
          <Popover>
            <PopoverTrigger asChild>
              <Button
                id="date-range"
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
                onSelect={onDateRangeChange}
                numberOfMonths={2}
              />
            </PopoverContent>
          </Popover>
        </div>

        <div className="min-w-[140px] space-y-2">
          <Label htmlFor="exercise-filter" className="font-semibold text-xs uppercase tracking-wide text-tactical-gray">Exercise Type</Label>
          <Select value={exerciseFilter} onValueChange={onExerciseFilterChange}>
            <SelectTrigger 
              id="exercise-filter" 
              className="border-army-tan/30 bg-cream"
              aria-label="Select exercise type"
            >
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
      
      {filtersActive && (
        <Button 
          variant="outline" 
          onClick={onClearFilters} 
          className="w-full border-brass-gold text-brass-gold hover:bg-brass-gold/10"
        >
          CLEAR FILTERS
        </Button>
      )}
    </div>
  );
};

export default HistoryFilterBar; 