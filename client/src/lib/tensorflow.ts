import * as tf from '@tensorflow/tfjs';
import * as posenet from '@tensorflow-models/posenet';

// Constants for pose detection
export const MIN_CONFIDENCE = 0.3;
export const POSE_MODEL_CONFIG = {
  architecture: 'MobileNetV1',
  outputStride: 16,
  inputResolution: { width: 640, height: 480 },
  multiplier: 0.75,
  quantBytes: 2
} as const;

// Body parts mapped by keypoint indices
export const BODY_PARTS = {
  NOSE: 0,
  LEFT_EYE: 1,
  RIGHT_EYE: 2,
  LEFT_EAR: 3,
  RIGHT_EAR: 4,
  LEFT_SHOULDER: 5,
  RIGHT_SHOULDER: 6,
  LEFT_ELBOW: 7,
  RIGHT_ELBOW: 8,
  LEFT_WRIST: 9,
  RIGHT_WRIST: 10,
  LEFT_HIP: 11,
  RIGHT_HIP: 12,
  LEFT_KNEE: 13,
  RIGHT_KNEE: 14,
  LEFT_ANKLE: 15,
  RIGHT_ANKLE: 16
};

// Interface for pose keypoint
export interface Keypoint {
  position: {
    x: number;
    y: number;
  };
  part: string;
  score: number;
}

// Exercise specific interfaces
export interface PushupState {
  isUp: boolean;
  isDown: boolean;
  count: number;
  formScore: number;
  feedback: string;
}

export interface PullupState {
  isUp: boolean;
  isDown: boolean;
  count: number;
  formScore: number;
  feedback: string;
}

export interface SitupState {
  isUp: boolean;
  isDown: boolean;
  count: number;
  formScore: number;
  feedback: string;
}

// Initialize PoseNet model
let poseNetModel: posenet.PoseNet | null = null;

export async function loadPoseNetModel(): Promise<posenet.PoseNet> {
  if (!poseNetModel) {
    poseNetModel = await posenet.load(POSE_MODEL_CONFIG);
  }
  return poseNetModel;
}

// Detect poses in a frame
export async function detectPose(video: HTMLVideoElement): Promise<posenet.Pose | null> {
  try {
    const model = await loadPoseNetModel();
    return await model.estimateSinglePose(video);
  } catch (error) {
    console.error('Pose detection error:', error);
    return null;
  }
}

// Calculate angle between three points
export function calculateAngle(a: Keypoint, b: Keypoint, c: Keypoint): number {
  const angleRadians = Math.atan2(
    c.position.y - b.position.y,
    c.position.x - b.position.x
  ) - Math.atan2(
    a.position.y - b.position.y,
    a.position.x - b.position.x
  );
  
  let angleDegrees = angleRadians * (180 / Math.PI);
  if (angleDegrees < 0) {
    angleDegrees += 360;
  }
  
  return angleDegrees;
}

// Get distance between two points
export function getDistance(p1: Keypoint, p2: Keypoint): number {
  return Math.sqrt(
    Math.pow(p2.position.x - p1.position.x, 2) +
    Math.pow(p2.position.y - p1.position.y, 2)
  );
}

// Push-up specific detection
export function detectPushup(pose: posenet.Pose, prevState: PushupState): PushupState {
  const keypoints = pose.keypoints;
  const leftShoulder = keypoints[BODY_PARTS.LEFT_SHOULDER];
  const rightShoulder = keypoints[BODY_PARTS.RIGHT_SHOULDER];
  const leftElbow = keypoints[BODY_PARTS.LEFT_ELBOW];
  const rightElbow = keypoints[BODY_PARTS.RIGHT_ELBOW];
  const leftWrist = keypoints[BODY_PARTS.LEFT_WRIST];
  const rightWrist = keypoints[BODY_PARTS.RIGHT_WRIST];
  const leftHip = keypoints[BODY_PARTS.LEFT_HIP];
  const rightHip = keypoints[BODY_PARTS.RIGHT_HIP];
  
  // Check if relevant keypoints are detected with enough confidence
  if (
    leftShoulder.score < MIN_CONFIDENCE ||
    rightShoulder.score < MIN_CONFIDENCE ||
    leftElbow.score < MIN_CONFIDENCE ||
    rightElbow.score < MIN_CONFIDENCE ||
    leftWrist.score < MIN_CONFIDENCE ||
    rightWrist.score < MIN_CONFIDENCE ||
    leftHip.score < MIN_CONFIDENCE ||
    rightHip.score < MIN_CONFIDENCE
  ) {
    return {
      ...prevState,
      feedback: "Position your full body in the frame"
    };
  }
  
  // Calculate angles for left and right arms
  const leftArmAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
  const rightArmAngle = calculateAngle(rightShoulder, rightElbow, rightWrist);
  
  // Calculate body alignment (back straight)
  const leftBodyAngle = calculateAngle(leftShoulder, leftHip, keypoints[BODY_PARTS.LEFT_KNEE]);
  const rightBodyAngle = calculateAngle(rightShoulder, rightHip, keypoints[BODY_PARTS.RIGHT_KNEE]);
  
  // Average arm angle for detection
  const avgArmAngle = (leftArmAngle + rightArmAngle) / 2;
  
  // Average body angle for detecting straight back
  const avgBodyAngle = (leftBodyAngle + rightBodyAngle) / 2;
  
  // Check if the person is in up position (arms extended)
  const isUp = avgArmAngle > 160;
  
  // Check if the person is in down position (arms bent)
  const isDown = avgArmAngle < 80;
  
  // Calculate form score
  let formScore = 80; // Base score
  let feedback = "";
  
  // Arm position check
  if (Math.abs(leftArmAngle - rightArmAngle) > 30) {
    formScore -= 20;
    feedback = "Keep arms evenly aligned";
  }
  
  // Back alignment check
  if (avgBodyAngle < 160 || avgBodyAngle > 200) {
    formScore -= 20;
    feedback = "Keep your back straight";
  }
  
  // Check for complete motion
  if (isDown && prevState.isUp && !prevState.isDown) {
    // Count a rep if it went from up to down
    return {
      isUp: false,
      isDown: true,
      count: prevState.count + 1,
      formScore,
      feedback
    };
  }
  
  // Update state for up position
  if (isUp && !prevState.isUp && prevState.isDown) {
    return {
      isUp: true,
      isDown: false,
      count: prevState.count,
      formScore,
      feedback: feedback || "Good form"
    };
  }
  
  // Provide feedback for partial movements
  if (!isUp && !isDown) {
    if (avgArmAngle > 120) {
      feedback = "Lower your body closer to the ground";
    } else if (avgArmAngle < 100) {
      feedback = "Extend your arms fully when pushing up";
    }
  }
  
  return {
    isUp: isUp || prevState.isUp,
    isDown: isDown || prevState.isDown,
    count: prevState.count,
    formScore,
    feedback: feedback || prevState.feedback
  };
}

// Pull-up specific detection
export function detectPullup(pose: posenet.Pose, prevState: PullupState): PullupState {
  const keypoints = pose.keypoints;
  const leftShoulder = keypoints[BODY_PARTS.LEFT_SHOULDER];
  const rightShoulder = keypoints[BODY_PARTS.RIGHT_SHOULDER];
  const leftElbow = keypoints[BODY_PARTS.LEFT_ELBOW];
  const rightElbow = keypoints[BODY_PARTS.RIGHT_ELBOW];
  const leftWrist = keypoints[BODY_PARTS.LEFT_WRIST];
  const rightWrist = keypoints[BODY_PARTS.RIGHT_WRIST];
  const nose = keypoints[BODY_PARTS.NOSE];
  
  // Check if relevant keypoints are detected with enough confidence
  if (
    leftShoulder.score < MIN_CONFIDENCE ||
    rightShoulder.score < MIN_CONFIDENCE ||
    leftElbow.score < MIN_CONFIDENCE ||
    rightElbow.score < MIN_CONFIDENCE ||
    leftWrist.score < MIN_CONFIDENCE ||
    rightWrist.score < MIN_CONFIDENCE ||
    nose.score < MIN_CONFIDENCE
  ) {
    return {
      ...prevState,
      feedback: "Position your upper body in the frame"
    };
  }
  
  // For pull-ups, check if chin is above or below hands (wrists)
  const avgWristY = (leftWrist.position.y + rightWrist.position.y) / 2;
  const noseY = nose.position.y;
  
  // Check if chin (nose) is above hands (wrists)
  const isUp = noseY < avgWristY - 10; // Nose is above wrists
  
  // Check if in down position (arms extended)
  const leftArmAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
  const rightArmAngle = calculateAngle(rightShoulder, rightElbow, rightWrist);
  const avgArmAngle = (leftArmAngle + rightArmAngle) / 2;
  
  const isDown = avgArmAngle > 160; // Arms extended in down position
  
  // Calculate form score
  let formScore = 80; // Base score
  let feedback = "";
  
  // Arm alignment check
  if (Math.abs(leftArmAngle - rightArmAngle) > 30) {
    formScore -= 20;
    feedback = "Keep arms evenly aligned";
  }
  
  // Check for complete motion
  if (isUp && prevState.isDown && !prevState.isUp) {
    // Count a rep if it went from down to up
    return {
      isUp: true,
      isDown: false,
      count: prevState.count + 1,
      formScore,
      feedback: feedback || "Good form"
    };
  }
  
  // Update state for down position
  if (isDown && !prevState.isDown && prevState.isUp) {
    return {
      isUp: false,
      isDown: true,
      count: prevState.count,
      formScore,
      feedback
    };
  }
  
  // Provide feedback
  if (!isUp && !isDown) {
    if (noseY > avgWristY) {
      feedback = "Pull your chin above the bar";
    } else if (avgArmAngle < 160) {
      feedback = "Extend your arms fully on the way down";
    }
  }
  
  return {
    isUp: isUp || prevState.isUp,
    isDown: isDown || prevState.isDown,
    count: prevState.count,
    formScore,
    feedback: feedback || prevState.feedback
  };
}

// Sit-up specific detection
export function detectSitup(pose: posenet.Pose, prevState: SitupState): SitupState {
  const keypoints = pose.keypoints;
  const leftShoulder = keypoints[BODY_PARTS.LEFT_SHOULDER];
  const rightShoulder = keypoints[BODY_PARTS.RIGHT_SHOULDER];
  const leftHip = keypoints[BODY_PARTS.LEFT_HIP];
  const rightHip = keypoints[BODY_PARTS.RIGHT_HIP];
  const leftKnee = keypoints[BODY_PARTS.LEFT_KNEE];
  const rightKnee = keypoints[BODY_PARTS.RIGHT_KNEE];
  
  // Check if relevant keypoints are detected with enough confidence
  if (
    leftShoulder.score < MIN_CONFIDENCE ||
    rightShoulder.score < MIN_CONFIDENCE ||
    leftHip.score < MIN_CONFIDENCE ||
    rightHip.score < MIN_CONFIDENCE ||
    leftKnee.score < MIN_CONFIDENCE ||
    rightKnee.score < MIN_CONFIDENCE
  ) {
    return {
      ...prevState,
      feedback: "Position your full body in the frame"
    };
  }
  
  // Calculate the angle between shoulders-hips-knees
  const leftAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
  const rightAngle = calculateAngle(rightShoulder, rightHip, rightKnee);
  const avgAngle = (leftAngle + rightAngle) / 2;
  
  // For sit-ups, the up position is when the upper body is at an angle to legs
  const isUp = avgAngle < 130; // Smaller angle means torso is up
  
  // Down position is when lying flat
  const isDown = avgAngle > 160; // Larger angle means torso is down
  
  // Calculate form score
  let formScore = 80; // Base score
  let feedback = "";
  
  // Check symmetry
  if (Math.abs(leftAngle - rightAngle) > 30) {
    formScore -= 20;
    feedback = "Keep your body centered during the sit-up";
  }
  
  // Check knee position (should be bent)
  const leftLegAngle = calculateAngle(leftHip, leftKnee, keypoints[BODY_PARTS.LEFT_ANKLE]);
  const rightLegAngle = calculateAngle(rightHip, rightKnee, keypoints[BODY_PARTS.RIGHT_ANKLE]);
  const avgLegAngle = (leftLegAngle + rightLegAngle) / 2;
  
  if (avgLegAngle > 160) { // Legs too straight
    formScore -= 20;
    feedback = "Bend your knees for proper form";
  }
  
  // Check for complete motion
  if (isUp && prevState.isDown && !prevState.isUp) {
    // Count a rep if it went from down to up
    return {
      isUp: true,
      isDown: false,
      count: prevState.count + 1,
      formScore,
      feedback: feedback || "Good form"
    };
  }
  
  // Update state for down position
  if (isDown && !prevState.isDown && prevState.isUp) {
    return {
      isUp: false,
      isDown: true,
      count: prevState.count,
      formScore,
      feedback
    };
  }
  
  // Provide feedback
  if (!isUp && !isDown) {
    if (avgAngle > 140) {
      feedback = "Lift your upper body higher";
    } else if (avgAngle < 150) {
      feedback = "Lower your back completely to the ground";
    }
  }
  
  return {
    isUp: isUp || prevState.isUp,
    isDown: isDown || prevState.isDown,
    count: prevState.count,
    formScore,
    feedback: feedback || prevState.feedback
  };
}

// Calculate relative positions for rendering points on the camera view
export function calculateRelativePositions(keypoints: Keypoint[], width: number, height: number) {
  return keypoints.map(point => ({
    part: point.part,
    score: point.score,
    position: {
      x: point.position.x / width * 100,
      y: point.position.y / height * 100
    }
  }));
}

// Calculate lines to draw between keypoints
export function calculatePoseLines(keypoints: Keypoint[]) {
  const lines = [
    // Head connections
    [BODY_PARTS.LEFT_EAR, BODY_PARTS.LEFT_EYE],
    [BODY_PARTS.LEFT_EYE, BODY_PARTS.NOSE],
    [BODY_PARTS.NOSE, BODY_PARTS.RIGHT_EYE],
    [BODY_PARTS.RIGHT_EYE, BODY_PARTS.RIGHT_EAR],
    
    // Torso connections
    [BODY_PARTS.LEFT_SHOULDER, BODY_PARTS.RIGHT_SHOULDER],
    [BODY_PARTS.LEFT_SHOULDER, BODY_PARTS.LEFT_HIP],
    [BODY_PARTS.RIGHT_SHOULDER, BODY_PARTS.RIGHT_HIP],
    [BODY_PARTS.LEFT_HIP, BODY_PARTS.RIGHT_HIP],
    
    // Arms connections
    [BODY_PARTS.LEFT_SHOULDER, BODY_PARTS.LEFT_ELBOW],
    [BODY_PARTS.LEFT_ELBOW, BODY_PARTS.LEFT_WRIST],
    [BODY_PARTS.RIGHT_SHOULDER, BODY_PARTS.RIGHT_ELBOW],
    [BODY_PARTS.RIGHT_ELBOW, BODY_PARTS.RIGHT_WRIST],
    
    // Legs connections
    [BODY_PARTS.LEFT_HIP, BODY_PARTS.LEFT_KNEE],
    [BODY_PARTS.LEFT_KNEE, BODY_PARTS.LEFT_ANKLE],
    [BODY_PARTS.RIGHT_HIP, BODY_PARTS.RIGHT_KNEE],
    [BODY_PARTS.RIGHT_KNEE, BODY_PARTS.RIGHT_ANKLE],
  ];
  
  // Filter out any lines with low confidence keypoints
  return lines.filter(([a, b]) => 
    keypoints[a] && keypoints[b] &&
    keypoints[a].score > MIN_CONFIDENCE &&
    keypoints[b].score > MIN_CONFIDENCE
  ).map(([a, b]) => ({
    from: keypoints[a],
    to: keypoints[b]
  }));
}
