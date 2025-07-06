import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Dumbbell, History as HistoryIcon, ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { SectionCard } from "@/components/ui/card";
import { ExerciseResponse } from '@/lib/types';
import { formatTime } from '@/lib/utils';

// Import the exercise PNG images 
import pushupImage from '@/assets/pushup.png';
import pullupImage from '@/assets/pullup.png';
import situpImage from '@/assets/situp.png';
import runningImage from '@/assets/running.png';

interface HistoryTableProps {
  filteredHistory: ExerciseResponse[];
  exercises: ExerciseResponse[];
  page: number;
  totalPages: number;
  totalCount: number;
  isFetching: boolean;
  setPage: (page: number) => void;
}

export const HistoryTable: React.FC<HistoryTableProps> = ({
  filteredHistory,
  exercises,
  page,
  totalPages,
  totalCount,
  isFetching,
  setPage,
}) => {
  const navigate = useNavigate();

  return (
    <SectionCard
      title="Training Record"
      description="Detailed log of workouts matching your filters"
      icon={<HistoryIcon className="size-5" />}
      contentClassName="bg-white"
    >
      {filteredHistory.length > 0 ? (
        <div className="space-y-2">
          {filteredHistory.map((session) => (
            <div 
              key={session.id} 
              className="flex items-center justify-between p-4 bg-white hover:bg-brass-gold hover:bg-opacity-5 cursor-pointer rounded-md"
              onClick={() => navigate(`/history/${session.id}`)}
            >
              <div className="flex items-center">
                <div className="mr-4 flex size-10 items-center justify-center rounded-full border border-brass-gold border-opacity-30 bg-brass-gold bg-opacity-10">
                  {session.exercise_type === 'pushup' ? 
                    <img src={pushupImage} alt="Push-ups" className="size-6" /> :
                  session.exercise_type === 'pullup' ? 
                    <img src={pullupImage} alt="Pull-ups" className="size-6" /> :
                  session.exercise_type === 'situp' ? 
                    <img src={situpImage} alt="Sit-ups" className="size-6" /> :
                  session.exercise_type === 'run' ? 
                    <img src={runningImage} alt="Two-Mile Run" className="size-6" /> :
                    <Dumbbell className="size-5 text-brass-gold" />
                  }
                </div>
                <div>
                  <h3 className="font-sans text-base font-medium uppercase text-command-black">
                    {session.exercise_type === 'pushup' ? 'PUSH-UPS' :
                     session.exercise_type === 'pullup' ? 'PULL-UPS' :
                     session.exercise_type === 'situp' ? 'SIT-UPS' :
                     session.exercise_type === 'run' ? 'TWO-MILE RUN' :
                     session.exercise_type.toUpperCase()}
                  </h3>
                  <p className="text-xs text-tactical-gray">
                    {(() => {
                      const date = new Date(session.created_at);
                      const day = date.getDate();
                      const month = date.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
                      const year = date.getFullYear();
                      const hours = date.getHours();
                      const minutes = date.getMinutes();
                      const militaryTime = `${hours.toString().padStart(2, '0')}${minutes.toString().padStart(2, '0')}`;
                      return `${day}${month}${year} · ${militaryTime}`;
                    })()}
                    {session.exercise_type === 'run' && session.time_in_seconds ? ` · ${formatTime(session.time_in_seconds)}` : ''}
                  </p>
                </div>
              </div>
              <div className="font-heading text-xl text-brass-gold">
                {session.exercise_type === 'run' && session.time_in_seconds
                  ? `${Math.floor(session.time_in_seconds / 60)}:${(session.time_in_seconds % 60).toString().padStart(2, '0')}`
                  : session.reps !== undefined && session.reps !== null
                    ? `${session.reps} reps`
                    : '-'}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="rounded-card overflow-hidden bg-white p-8 text-center">
          <p className="font-semibold text-sm text-tactical-gray">
            {exercises.length > 0 
              ? "No sessions found matching your current filters."
              : "Loading sessions..."}
          </p>
        </div>
      )}
      
      {filteredHistory.length > 0 && (
        <div className="mt-4 flex items-center justify-between">
          <div className="text-sm text-tactical-gray">
            Page {page} of {totalPages} ({totalCount} total records)
          </div>
          <div className="space-x-2">
            <Button
              variant="outline"
              size="small"
              onClick={() => setPage(Math.max(page - 1, 1))}
              disabled={page <= 1 || isFetching}
              className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
            >
              <ChevronLeft className="mr-1 size-4" /> PREV
            </Button>
            <Button
              variant="outline"
              size="small"
              onClick={() => setPage(Math.min(page + 1, totalPages))}
              disabled={page >= totalPages || isFetching}
              className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
            >
              NEXT <ChevronRight className="ml-1 size-4" />
            </Button>
          </div>
        </div>
      )}
    </SectionCard>
  );
};