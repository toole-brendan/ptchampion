/**
 * Services index file
 * 
 * Exports all services to allow importing from '@/services' instead of individual files.
 * Example: import { poseDetectorService, PoseLandmarkIndex } from '@/services';
 */

// Export PoseDetectorService
export * from './PoseDetectorService';
import PoseDetectorService from './PoseDetectorService';
export { PoseDetectorService };

// Export PoseLandmarkIndex and helper functions
export * from './PoseLandmarkIndex';
import PoseLandmarkIndex from './PoseLandmarkIndex';
export { PoseLandmarkIndex }; 