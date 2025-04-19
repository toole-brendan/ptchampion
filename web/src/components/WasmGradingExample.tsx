import React, { useEffect, useState } from 'react';

// Placeholder for the WASM module (in production this would be imported from the built WASM)
// These declarations will be replaced by the real implementations from the WASM module
declare global {
  interface Window {
    calculateExerciseScore: (exerciseType: string, performanceValue: number) => any;
    gradePushupPose: (poseData: string, previousState: string | null) => any;
    gradingModuleInitialized: boolean;
  }
}

// Mock implementations that will be replaced by the actual WASM functions
const initGradingModule = async () => {
  // In production, this would load the WASM module
  console.log("Mock WASM module initialization (placeholder)");
  window.gradingModuleInitialized = true;
  window.calculateExerciseScore = (exerciseType, performanceValue) => {
    return { success: true, score: Math.round(performanceValue * 1.5) };
  };
  window.gradePushupPose = (poseData, previousState) => {
    const data = JSON.parse(poseData);
    const isDownPosition = data.keypoints.some(
      (kp: any) => kp.name === "leftElbow" && kp.x > 0.3
    );
    
    // Mock rep counting logic
    let repCount = 0;
    let state = "{}";
    if (previousState) {
      try {
        const prevState = JSON.parse(previousState);
        repCount = prevState.repCount || 0;
        if (isDownPosition && prevState.lastPosition === "up") {
          repCount++;
        }
        state = JSON.stringify({
          ...prevState,
          lastPosition: isDownPosition ? "down" : "up",
          repCount
        });
      } catch (e) {
        state = JSON.stringify({ lastPosition: isDownPosition ? "down" : "up", repCount: 0 });
      }
    } else {
      state = JSON.stringify({ lastPosition: isDownPosition ? "down" : "up", repCount: 0 });
    }
    
    return {
      success: true,
      result: {
        isValid: true,
        repCounted: false,
        formScore: 0.85,
        feedback: isDownPosition ? "Push up" : "Lower body",
        state: isDownPosition ? "down" : "up"
      },
      repCount,
      state
    };
  };
  return Promise.resolve();
};

const calculateScore = async (exerciseType: string, performanceValue: number) => {
  if (!window.gradingModuleInitialized) {
    await initGradingModule();
  }
  return window.calculateExerciseScore(exerciseType, performanceValue);
};

const gradePushup = async (poseData: any, previousState: string | null) => {
  if (!window.gradingModuleInitialized) {
    await initGradingModule();
  }
  return window.gradePushupPose(JSON.stringify(poseData), previousState);
};

// Mock pose data for demonstration
const mockPoseData = {
  keypoints: [
    { name: "leftShoulder", x: 0.3, y: 0.4, confidence: 0.95 },
    { name: "rightShoulder", x: 0.7, y: 0.4, confidence: 0.96 },
    { name: "leftElbow", x: 0.2, y: 0.6, confidence: 0.94 },
    { name: "rightElbow", x: 0.8, y: 0.6, confidence: 0.93 },
    { name: "leftWrist", x: 0.1, y: 0.7, confidence: 0.92 },
    { name: "rightWrist", x: 0.9, y: 0.7, confidence: 0.91 },
    { name: "leftHip", x: 0.4, y: 0.8, confidence: 0.95 },
    { name: "rightHip", x: 0.6, y: 0.8, confidence: 0.94 },
    { name: "leftKnee", x: 0.35, y: 0.9, confidence: 0.93 },
    { name: "rightKnee", x: 0.65, y: 0.9, confidence: 0.92 },
    { name: "leftAnkle", x: 0.3, y: 1.0, confidence: 0.9 },
    { name: "rightAnkle", x: 0.7, y: 1.0, confidence: 0.9 }
  ]
};

// Mock pose in "down" position
const downPoseData = {
  keypoints: [
    { name: "leftShoulder", x: 0.3, y: 0.4, confidence: 0.95 },
    { name: "rightShoulder", x: 0.7, y: 0.4, confidence: 0.96 },
    { name: "leftElbow", x: 0.35, y: 0.5, confidence: 0.94 }, // elbows more bent
    { name: "rightElbow", x: 0.65, y: 0.5, confidence: 0.93 },
    { name: "leftWrist", x: 0.3, y: 0.45, confidence: 0.92 }, // wrists closer to body
    { name: "rightWrist", x: 0.7, y: 0.45, confidence: 0.91 },
    { name: "leftHip", x: 0.4, y: 0.8, confidence: 0.95 },
    { name: "rightHip", x: 0.6, y: 0.8, confidence: 0.94 },
    { name: "leftKnee", x: 0.35, y: 0.9, confidence: 0.93 },
    { name: "rightKnee", x: 0.65, y: 0.9, confidence: 0.92 },
    { name: "leftAnkle", x: 0.3, y: 1.0, confidence: 0.9 },
    { name: "rightAnkle", x: 0.7, y: 1.0, confidence: 0.9 }
  ]
};

const WasmGradingExample: React.FC = () => {
  const [isWasmLoaded, setIsWasmLoaded] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [score, setScore] = useState<number | null>(null);
  const [gradingResult, setGradingResult] = useState<any>(null);
  const [gradingState, setGradingState] = useState<string | null>(null);
  const [repCount, setRepCount] = useState(0);
  
  // Load WASM module on component mount
  useEffect(() => {
    const loadWasm = async () => {
      try {
        await initGradingModule();
        setIsWasmLoaded(true);
        console.log("WASM grading module loaded successfully");
      } catch (err) {
        setError(`Failed to load WASM module: ${err}`);
        console.error("Failed to load WASM module:", err);
      }
    };
    
    loadWasm();
  }, []);
  
  // Calculate a push-up score
  const handleCalculateScore = async () => {
    if (!isWasmLoaded) {
      setError("WASM module not loaded yet");
      return;
    }
    
    try {
      const result = await calculateScore("pushup", 50);
      if (result.success) {
        setScore(result.score);
        setError(null);
      } else {
        setError(result.error || "Unknown error");
      }
    } catch (err) {
      setError(`Error calculating score: ${err}`);
    }
  };
  
  // Grade a push-up pose
  const handleGradePose = async (isDown = false) => {
    if (!isWasmLoaded) {
      setError("WASM module not loaded yet");
      return;
    }
    
    try {
      // Use the pose data and current state (if any)
      const poseToGrade = isDown ? downPoseData : mockPoseData;
      const result = await gradePushup(poseToGrade, gradingState);
      
      if (result.success) {
        setGradingResult(result.result);
        setGradingState(result.state);
        setRepCount(result.repCount || 0);
        setError(null);
      } else {
        setError(result.error || "Unknown error");
      }
    } catch (err) {
      setError(`Error grading pose: ${err}`);
    }
  };
  
  return (
    <div className="rounded-lg bg-cream p-4 shadow">
      <h2 className="mb-4 font-heading text-xl">WASM Grading Demo</h2>
      
      <div className="mb-4">
        <p className="mb-2">Status: {isWasmLoaded ? "WASM module loaded" : "Loading WASM module..."}</p>
        {error && <p className="text-red-500">{error}</p>}
      </div>
      
      <div className="mb-4">
        <button 
          onClick={handleCalculateScore}
          disabled={!isWasmLoaded}
          className="mr-2 rounded-md bg-brass-gold px-4 py-2 text-deep-ops disabled:opacity-50"
        >
          Calculate 50 Push-ups Score
        </button>
        {score !== null && (
          <span className="ml-2 font-mono text-lg">Score: {score}</span>
        )}
      </div>
      
      <div className="mb-4">
        <button 
          onClick={() => handleGradePose(false)}
          disabled={!isWasmLoaded}
          className="mr-2 rounded-md bg-brass-gold px-4 py-2 text-deep-ops disabled:opacity-50"
        >
          Grade "Up" Position
        </button>
        <button 
          onClick={() => handleGradePose(true)}
          disabled={!isWasmLoaded}
          className="rounded-md bg-brass-gold px-4 py-2 text-deep-ops disabled:opacity-50"
        >
          Grade "Down" Position
        </button>
      </div>
      
      {gradingResult && (
        <div className="mb-4 rounded-md bg-white p-3">
          <h3 className="mb-2 font-heading">Grading Result:</h3>
          <div className="mb-2 grid grid-cols-2 gap-2">
            <div>State: <span className="font-mono">{gradingResult.state}</span></div>
            <div>Reps: <span className="font-mono">{repCount}</span></div>
            <div>Valid: <span className="font-mono">{gradingResult.isValid ? "Yes" : "No"}</span></div>
            <div>Rep Counted: <span className="font-mono">{gradingResult.repCounted ? "Yes" : "No"}</span></div>
            <div>Form Score: <span className="font-mono">{Math.round(gradingResult.formScore * 100)}%</span></div>
          </div>
          <div>Feedback: <span className="italic">{gradingResult.feedback}</span></div>
        </div>
      )}
      
      <div className="mt-6 text-sm text-gray-500">
        <p>Note: This component demonstrates the WebAssembly integration of the grading logic.</p>
        <p>The same code can be used in iOS (via Wasmer-Swift) and Android (via Wasmtime-JNI).</p>
      </div>
    </div>
  );
};

export default WasmGradingExample; 