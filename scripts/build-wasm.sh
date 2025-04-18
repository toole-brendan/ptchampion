#!/bin/bash
set -e

# Check if TinyGo is installed
if ! command -v tinygo &> /dev/null; then
    echo "TinyGo is not installed. Please install it from https://tinygo.org/getting-started/install/"
    exit 1
fi

echo "Building PT Champion grading WASM module..."

# Create output directory if it doesn't exist
mkdir -p web/public/wasm

# Build with TinyGo
tinygo build -o web/public/wasm/grading.wasm -target wasm ./cmd/wasm/main.go

# Copy the JavaScript loader
cp "$(tinygo env TINYGOROOT)/targets/wasm_exec.js" web/public/wasm/

echo "Creating JavaScript wrapper..."

# Create a wrapper JavaScript file to make the WASM module easier to use
cat > web/public/wasm/grading_wrapper.js << 'EOF'
// PT Champion grading WASM module wrapper

// Initialize the WASM module
export async function initGradingModule() {
    if (window.gradingModuleInitialized) {
        return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
        // Load the TinyGo WASM runtime
        const go = new Go();
        
        if (!WebAssembly.instantiateStreaming) {
            // Fallback for browsers without instantiateStreaming
            fetch('/wasm/grading.wasm')
                .then(response => response.arrayBuffer())
                .then(bytes => WebAssembly.instantiate(bytes, go.importObject))
                .then(result => {
                    go.run(result.instance);
                    window.gradingModuleInitialized = true;
                    resolve();
                })
                .catch(err => {
                    console.error('Failed to initialize WASM module:', err);
                    reject(err);
                });
        } else {
            // Modern approach using instantiateStreaming
            WebAssembly.instantiateStreaming(fetch('/wasm/grading.wasm'), go.importObject)
                .then(result => {
                    go.run(result.instance);
                    window.gradingModuleInitialized = true;
                    resolve();
                })
                .catch(err => {
                    console.error('Failed to initialize WASM module:', err);
                    reject(err);
                });
        }
    });
}

// Calculate exercise score based on performance (reps or time)
export async function calculateScore(exerciseType, performanceValue) {
    await initGradingModule();
    return window.calculateExerciseScore(exerciseType, performanceValue);
}

// Grade a push-up pose and track repetitions
export async function gradePushup(poseData, previousState = null) {
    await initGradingModule();
    return window.gradePushupPose(JSON.stringify(poseData), previousState);
}
EOF

echo "Creating TypeScript type definitions..."

# Create TypeScript type definitions
cat > web/src/@types/grading-wasm.d.ts << 'EOF'
declare module '@wasm/grading' {
    /**
     * Initialize the grading WASM module
     */
    export function initGradingModule(): Promise<void>;
    
    /**
     * Calculate a score for an exercise based on performance value
     * @param exerciseType Type of exercise ('pushup', 'situp', 'pullup', 'run')
     * @param performanceValue Number of reps or time in seconds
     * @returns Score result object
     */
    export function calculateScore(exerciseType: string, performanceValue: number): Promise<{
        success: boolean;
        score?: number;
        error?: string;
    }>;
    
    /**
     * Grade a push-up pose and track repetitions
     * @param poseData Pose keypoints data
     * @param previousState Optional previously returned state string
     * @returns Grading result and updated state
     */
    export function gradePushup(
        poseData: {
            keypoints: Array<{
                name: string;
                x: number;
                y: number;
                confidence: number;
            }>
        }, 
        previousState?: string | null
    ): Promise<{
        success: boolean;
        result?: {
            isValid: boolean;
            repCounted: boolean;
            formScore: number;
            feedback: string;
            state: string;
        };
        repCount?: number;
        state?: string;
        error?: string;
    }>;
}
EOF

echo "WASM build complete!"
echo "Files created:"
echo "- web/public/wasm/grading.wasm"
echo "- web/public/wasm/wasm_exec.js"
echo "- web/public/wasm/grading_wrapper.js"
echo "- web/src/@types/grading-wasm.d.ts"
echo ""
echo "To use in your web app:"
echo "1. Include wasm_exec.js in your HTML"
echo "2. Import functions from grading_wrapper.js"
echo "3. Call initGradingModule() before using other functions" 