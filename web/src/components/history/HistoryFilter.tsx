import React from 'react';
import { format } from "date-fns";
import { Calendar as CalendarIcon, Dumbbell } from "lucide-react";
import { DateRange as RDDateRange } from "react-day-picker";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SectionCard } from "@/components/ui/card";

// Filter button component
interface FilterButtonProps {
  label: string;
  icon?: React.ComponentType<{ className?: string }>;
  active: boolean;
  onClick: () => void;
}

const FilterButton: React.FC<FilterButtonProps> = ({ label, icon: Icon, active, onClick }) => (
  <Button 
    variant={active ? "default" : "outline"} 
    className={cn(
      "rounded-full transition-all",
      active 
        ? "bg-brass-gold text-white" 
        : "bg-cream text-command-black border-olive-mist/30"
    )}
    onClick={onClick}
  >
    {Icon && <Icon className="mr-1 size-4" />}
    {label}
  </Button>
);

interface HistoryFilterProps {
  exerciseTypes: string[];
  exerciseFilter: string;
  setExerciseFilter: (value: string) => void;
  dateRange: RDDateRange | undefined;
  setDateRange: (value: RDDateRange | undefined) => void;
}

export const HistoryFilter: React.FC<HistoryFilterProps> = ({
  exerciseTypes,
  exerciseFilter,
  setExerciseFilter,
  dateRange,
  setDateRange,
}) => {
  return (
    <SectionCard
      title="Filter Workouts"
      description="Choose an exercise type or date range"
      className="animate-fade-in"
    >
      {/* Exercise Filter Bar */}
      <div className="overflow-x-auto pb-4 -mx-1 px-1">
        <div className="flex items-center space-x-2 mb-4">
          {exerciseTypes.map(type => (
            <FilterButton
              key={type}
              label={
                type === 'All' ? 'All Exercises' :
                type === 'pushup' ? 'PUSH-UPS' :
                type === 'pullup' ? 'PULL-UPS' :
                type === 'situp' ? 'SIT-UPS' :
                type === 'run' ? 'TWO-MILE RUN' :
                type.toUpperCase()
              }
              icon={type === 'All' ? Dumbbell : undefined}
              active={exerciseFilter === type}
              onClick={() => setExerciseFilter(type)}
            />
          ))}
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-4">
        {/* Date Range Field */}
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
                onSelect={(range) => {
                  // @ts-ignore - Type compatibility issue between the DateRange types
                  setDateRange(range);
                }}
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
          CLEAR ALL FILTERS
        </Button>
      )}
    </SectionCard>
  );
};