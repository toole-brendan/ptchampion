import { useState } from "react";
import { useLocation } from "wouter";
import { useMutation } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import Navigation from "@/components/navigation";
import { Button } from "@/components/ui/button";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { ArrowLeft, Clock, CheckCircle } from "lucide-react";

type WatchDevice = {
  id: string;
  name: string;
  connected: boolean;
};

export default function RunPage() {
  const [, setLocation] = useLocation();
  const { user } = useAuth();
  
  // State for connected watches
  const [watches, setWatches] = useState<WatchDevice[]>([
    { id: "apple-watch", name: "Apple Watch", connected: true },
    { id: "garmin", name: "Garmin Forerunner", connected: false },
    { id: "fitbit", name: "Fitbit Versa", connected: false }
  ]);
  
  // State for manual entry
  const [showManualEntry, setShowManualEntry] = useState(false);
  const [minutes, setMinutes] = useState("14");
  const [seconds, setSeconds] = useState("32");
  
  // Handle watch connection toggle
  const toggleConnection = (id: string) => {
    setWatches(watches.map(watch => 
      watch.id === id ? { ...watch, connected: !watch.connected } : watch
    ));
  };
  
  // Complete run mutation
  const completeMutation = useMutation({
    mutationFn: async (timeInSeconds: number) => {
      // Get run exercise ID (assuming it's 4 based on seed data)
      const exerciseId = 4;
      
      const data = {
        exerciseId,
        timeInSeconds,
        formScore: 100, // Not really applicable for runs
        completed: true
      };
      
      const res = await apiRequest("POST", "/api/user-exercises", data);
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/user-exercises/latest/all"] });
      setLocation("/");
    }
  });
  
  // Handle start run with connected watch
  const handleStartRun = () => {
    // In a real app, this would initialize communication with the watch
    // For this demo, we'll just simulate a completed run
    const timeInSeconds = parseInt(minutes) * 60 + parseInt(seconds);
    completeMutation.mutate(timeInSeconds);
  };
  
  // Handle manual entry submission
  const handleManualEntry = () => {
    const mins = parseInt(minutes || "0");
    const secs = parseInt(seconds || "0");
    
    if (isNaN(mins) || isNaN(secs) || mins < 0 || secs < 0 || secs > 59) {
      return; // Invalid input
    }
    
    const timeInSeconds = mins * 60 + secs;
    completeMutation.mutate(timeInSeconds);
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      {/* Header */}
      <header className="bg-white border-b border-slate-200">
        <div className="container px-4 py-3 mx-auto flex items-center justify-between">
          <div>
            <button className="flex items-center text-accent" onClick={() => setLocation("/")}>
              <ArrowLeft className="h-5 w-5 mr-1" />
              Back
            </button>
          </div>
          <h2 className="text-2xl font-bold">2-mile Run</h2>
          <div></div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <section className="py-6 px-4 lg:px-8">
          <div className="container mx-auto max-w-5xl">
            {!showManualEntry ? (
              <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
                <div className="flex flex-col items-center justify-center py-6">
                  <div className="w-24 h-24 rounded-full bg-slate-100 flex items-center justify-center mb-4">
                    <Clock className="h-12 w-12 text-slate-400" />
                  </div>
                  <h3 className="text-xl font-bold mb-2">Connect Smartwatch</h3>
                  <p className="text-slate-500 text-center max-w-md mb-6">Connect your smartwatch to track your 2-mile run. Ensure GPS is enabled on your device.</p>
                  
                  <div className="w-full max-w-sm mb-8">
                    {watches.map(watch => (
                      <div key={watch.id} className="bg-slate-100 rounded-lg p-4 mb-4 flex items-center justify-between">
                        <div className="flex items-center">
                          <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center mr-3">
                            <Clock className={`h-6 w-6 ${watch.connected ? 'text-accent' : 'text-slate-400'}`} />
                          </div>
                          <div>
                            <div className="font-medium">{watch.name}</div>
                            <div className="text-xs text-slate-500">
                              {watch.connected ? 'Connected' : 'Not connected'}
                            </div>
                          </div>
                        </div>
                        {watch.connected ? (
                          <div className="w-5 h-5 bg-green-500 rounded-full"></div>
                        ) : (
                          <button 
                            className="text-xs font-medium text-accent"
                            onClick={() => toggleConnection(watch.id)}
                          >
                            Connect
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                  
                  <div className="space-y-3 w-full max-w-sm">
                    <button 
                      className="w-full bg-accent text-white py-3 px-4 rounded-lg font-medium"
                      onClick={handleStartRun}
                      disabled={!watches.some(w => w.connected)}
                    >
                      Start 2-mile Run
                    </button>
                    <button 
                      className="w-full bg-white border border-slate-200 py-3 px-4 rounded-lg font-medium"
                      onClick={() => setShowManualEntry(true)}
                    >
                      Manual Entry
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
                <div className="flex flex-col items-center justify-center py-6">
                  <div className="w-24 h-24 rounded-full bg-slate-100 flex items-center justify-center mb-4">
                    <Clock className="h-12 w-12 text-slate-400" />
                  </div>
                  <h3 className="text-xl font-bold mb-2">Manual Time Entry</h3>
                  <p className="text-slate-500 text-center max-w-md mb-6">Enter your 2-mile run time manually.</p>
                  
                  <div className="w-full max-w-sm mb-8">
                    <div className="flex items-center justify-center space-x-2 mb-6">
                      <div className="w-20">
                        <label className="block text-sm font-medium text-gray-700 mb-1 text-center">Minutes</label>
                        <input
                          type="number"
                          min="0"
                          max="59"
                          value={minutes}
                          onChange={(e) => setMinutes(e.target.value)}
                          className="w-full text-center border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-accent"
                        />
                      </div>
                      <span className="text-2xl font-bold">:</span>
                      <div className="w-20">
                        <label className="block text-sm font-medium text-gray-700 mb-1 text-center">Seconds</label>
                        <input
                          type="number"
                          min="0"
                          max="59"
                          value={seconds}
                          onChange={(e) => setSeconds(e.target.value)}
                          className="w-full text-center border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-accent"
                        />
                      </div>
                    </div>
                  </div>
                  
                  <div className="space-y-3 w-full max-w-sm">
                    <button 
                      className="w-full bg-accent text-white py-3 px-4 rounded-lg font-medium"
                      onClick={handleManualEntry}
                    >
                      Save Run Time
                    </button>
                    <button 
                      className="w-full bg-white border border-slate-200 py-3 px-4 rounded-lg font-medium"
                      onClick={() => setShowManualEntry(false)}
                    >
                      Back to Watch Connection
                    </button>
                  </div>
                </div>
              </div>
            )}
            
            <div className="bg-white rounded-xl shadow-sm p-4">
              <h3 className="text-lg font-semibold mb-3">Before You Start</h3>
              <ul className="space-y-2">
                <li className="flex">
                  <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                  <span>Ensure your device has GPS enabled for accurate tracking</span>
                </li>
                <li className="flex">
                  <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                  <span>Find a flat, measured 2-mile course for best results</span>
                </li>
                <li className="flex">
                  <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                  <span>Warm up properly before beginning your run</span>
                </li>
                <li className="flex">
                  <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                  <span>Keep your smartwatch visible and accessible during the run</span>
                </li>
              </ul>
            </div>
          </div>
        </section>
      </main>

      {/* Bottom Navigation */}
      <Navigation active="home" />
    </div>
  );
}
