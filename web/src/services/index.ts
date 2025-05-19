/**
 * Services index file
 * 
 * Exports all services to allow importing from '@/services' instead of individual files.
 * Example: import { poseDetectorService, PoseLandmarkIndex } from '@/services';
 */

// Export PoseDetectorService
export * from '@/services/PoseDetectorService';
import PoseDetectorService from '@/services/PoseDetectorService';
export { PoseDetectorService };

// Export PoseLandmarkIndex and helper functions
export * from '@/services/PoseLandmarkIndex';
import PoseLandmarkIndex from '@/services/PoseLandmarkIndex';
export { PoseLandmarkIndex }; 