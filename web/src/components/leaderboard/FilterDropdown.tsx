import React from 'react';
import { cn } from '@/lib/utils';
import { ChevronDown, Check } from 'lucide-react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";

interface FilterDropdownProps {
  label: string;
  value: string;
  options: Array<{
    value: string;
    label: string;
  }>;
  onChange: (value: string) => void;
  className?: string;
}

const FilterDropdown: React.FC<FilterDropdownProps> = ({
  label,
  value,
  options,
  onChange,
  className
}) => {
  return (
    <div className={cn("space-y-1", className)}>
      <Label className="text-xs font-mono uppercase tracking-wider text-tactical-gray font-medium">
        {label}
      </Label>
      <Select value={value} onValueChange={onChange}>
        <SelectTrigger 
          className={cn(
            "bg-white border-deep-ops/30 text-deep-ops",
            "hover:border-deep-ops/50 focus:border-brass-gold focus:ring-brass-gold",
            "transition-colors duration-200"
          )}
          aria-label={`Select ${label.toLowerCase()}`}
        >
          <SelectValue>
            <span className="text-xs font-mono uppercase tracking-wide font-medium">
              {options.find(opt => opt.value === value)?.label || value}
            </span>
          </SelectValue>
        </SelectTrigger>
        <SelectContent className="bg-white border-deep-ops/30">
          {options.map((option) => (
            <SelectItem 
              key={option.value} 
              value={option.value}
              className={cn(
                "text-xs font-mono uppercase tracking-wide",
                "hover:bg-brass-gold/10 focus:bg-brass-gold/10",
                "cursor-pointer"
              )}
            >
              <div className="flex items-center justify-between w-full">
                <span>{option.label}</span>
                {value === option.value && (
                  <Check className="w-3 h-3 text-brass-gold ml-2" />
                )}
              </div>
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
};

export default FilterDropdown; 