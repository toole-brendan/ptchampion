import { useEffect, useRef, useState } from "react";
import { PoseDetector, PoseDetectorResult } from "./poseDetector";

export function usePoseDetector(model: "lite" | "full" | "heavy" = "full") {
  const [result, setResult] = useState<PoseDetectorResult | null>(null);
  const detectorRef = useRef<PoseDetector>();
  const videoRef = useRef<HTMLVideoElement>(null);

  // 1. boot camera + detector
  useEffect(() => {
    (async () => {
      detectorRef.current = new PoseDetector();
      await detectorRef.current.init(
        `/models/pose_landmarker_${model}.task`
      );

      const stream = await navigator.mediaDevices.getUserMedia({
        video: { width: 1280, height: 720 }
      });
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        await videoRef.current.play();
        tickRef.current!(); // kick render loop
      }
    })();
    return () => {
      if (videoRef.current?.srcObject) {
        (videoRef.current.srcObject as MediaStream)
          .getTracks()
          .forEach((t) => t.stop());
      }
    };
  }, [model]);

  // 2. frame loop
  const tickRef = useRef<() => void>();
  tickRef.current = () => {
    const det = detectorRef.current?.detect(videoRef.current!);
    if (det) setResult(det);
    requestAnimationFrame(tickRef.current!);
  };

  return { videoRef, pose: result };
} 