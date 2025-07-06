import React from 'react';
import { Loader2 } from 'lucide-react';

interface RunningFormProps {
  formMinutes: number;
  formSeconds: number;
  formDistance: number;
  notes: string;
  isSubmitting: boolean;
  isFinished: boolean;
  success: boolean;
  apiError: string | null;
  loggedGrade: number | null;
  onMinutesChange: (value: number) => void;
  onSecondsChange: (value: number) => void;
  onDistanceChange: (value: number) => void;
  onNotesChange: (value: string) => void;
  onSubmit: (e: React.FormEvent) => void;
  getTotalSecondsFromForm: () => number;
  formatTimeForDisplay: () => string;
}

export const RunningForm: React.FC<RunningFormProps> = ({
  formMinutes,
  formSeconds,
  formDistance,
  notes,
  isSubmitting,
  isFinished,
  success,
  apiError,
  loggedGrade,
  onMinutesChange,
  onSecondsChange,
  onDistanceChange,
  onNotesChange,
  onSubmit,
  getTotalSecondsFromForm,
  formatTimeForDisplay,
}) => {
  const EXERCISE_NAME = "Two-Mile Run";

  return (
    <div className="mx-auto max-w-3xl p-4">
      <div className="mb-8">
        <h1 className="mb-2 font-bold text-3xl">Log Your {EXERCISE_NAME}</h1>
        {isFinished && !success && (
           <p className="rounded-md border border-green-200 bg-green-50 p-3 text-green-600">
             Run tracked! Review the details below and click "Log Exercise" to save.
           </p>
        )}
        {!isFinished && !success && (
          <p className="text-gray-600">
            Complete the fields below to manually log your run, or use the tracker above.
          </p>
        )}
      </div>
      
      {success && (
        <div className="mb-6 rounded-md bg-green-50 p-4 text-green-800">
          Exercise logged successfully! 
          {loggedGrade !== null && ` Grade: ${loggedGrade}. `} 
          Redirecting to summary...
        </div>
      )}
      
      {apiError && (
        <div className="mb-6 rounded-md bg-red-50 p-4 text-red-800">
          {apiError}
        </div>
      )}
      
      <div className="rounded-lg bg-white p-6 shadow-md">
        <form onSubmit={onSubmit} className="space-y-6">
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Running Time (Minutes:Seconds)
            </label>
            <div className="flex space-x-2">
              <div className="w-1/2">
                <input
                  type="number"
                  min="0"
                  value={formMinutes}
                  onChange={(e) => onMinutesChange(parseInt(e.target.value))}
                  className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
                  placeholder="Minutes"
                  disabled={isSubmitting || (isFinished && !success)}
                  required
                />
              </div>
              <div className="w-1/2">
                <input
                  type="number"
                  min="0"
                  max="59"
                  value={formSeconds}
                  onChange={(e) => onSecondsChange(parseInt(e.target.value))}
                  className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
                  placeholder="Seconds"
                  disabled={isSubmitting || (isFinished && !success)}
                  required
                />
              </div>
            </div>
            <p className="mt-1 text-sm text-gray-500">
              {isFinished ? "Time from tracked run." : "Format: MM:SS (e.g., 13:30)"}
            </p>
          </div>
          
          <div>
            <label htmlFor="distance" className="mb-1 block text-sm font-medium text-gray-700">
              Distance (Miles)
            </label>
            <input
              id="distance"
              type="number"
              min="0"
              step="0.01"
              value={formDistance}
              onChange={(e) => onDistanceChange(parseFloat(e.target.value))}
              className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
              placeholder="2.0"
              disabled={isSubmitting || (isFinished && !success)}
              required
            />
            <p className="mt-1 text-sm text-gray-500">
              {isFinished ? "Distance from tracked run." : "Enter distance in miles (e.g., 2.0)"}
            </p>
          </div>
          
          <div>
            <label htmlFor="notes" className="mb-1 block text-sm font-medium text-gray-700">
              Notes (Optional)
            </label>
            <textarea
              id="notes"
              value={notes}
              onChange={(e) => onNotesChange(e.target.value)}
              rows={3}
              className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              disabled={isSubmitting}
              placeholder="Add any notes about this run..."
            />
          </div>
          
          <div className="flex items-center justify-between pt-4">
            <div>
              {getTotalSecondsFromForm() > 0 && (
                <div className="text-sm text-gray-500">
                  {isFinished ? "Logged time from tracker:" : "Manually entered time:"} {formatTimeForDisplay()}
                </div>
              )}
            </div>
            <button
              type="submit"
              disabled={isSubmitting || getTotalSecondsFromForm() <= 0 || formDistance <= 0 || success}
              className="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50"
            >
              {isSubmitting ? <Loader2 className="mr-2 size-4 animate-spin" /> : null}
              {isSubmitting ? 'Logging...' : 'Log Exercise'}
            </button>
          </div>
        </form>
      </div>
      
      <div className="mt-8 rounded-md bg-gray-50 p-4">
        <h2 className="mb-2 text-lg font-medium">Running Tips</h2>
        <ul className="list-disc space-y-1 pl-5">
          <li>Warm up with dynamic stretching before your run</li>
          <li>Maintain good posture with shoulders relaxed and back straight</li>
          <li>Focus on a steady, consistent pace rather than starting too fast</li>
          <li>Land midfoot rather than on your heels or toes</li>
          <li>Cool down with a slower pace at the end of your run</li>
          <li>Stay hydrated before, during, and after your run</li>
        </ul>
      </div>
    </div>
  );
};