import React from 'react';
import { Timer } from 'lucide-react';

interface RunningStatsProps {
  distanceMiles: number;
  formattedTime: string;
  pace: string;
}

export const RunningStats: React.FC<RunningStatsProps> = ({
  distanceMiles,
  formattedTime,
  pace,
}) => {
  return (
    <div className="grid grid-cols-3 gap-4 text-center">
      <div>
        <p className="text-sm font-medium text-muted-foreground">Distance</p>
        <p className="font-bold text-4xl text-foreground">
           {distanceMiles.toFixed(2)} <span className="text-xl font-normal">miles</span>
        </p>
      </div>
      <div>
        <p className="text-sm font-medium text-muted-foreground">Time</p>
        <p className="flex items-center justify-center font-bold text-4xl text-foreground">
          <Timer className="mr-1 inline-block size-6" />
          {formattedTime}
        </p>
      </div>
      <div>
        <p className="text-sm font-medium text-muted-foreground">Pace</p>
        <p className="font-bold text-4xl text-foreground">
          {pace}
        </p>
      </div>
    </div>
  );
};