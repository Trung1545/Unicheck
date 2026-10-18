// ==============================================================================
// UniCheck - MediaPipe Face Landmarker Service
// Handles model initialization, WASM runtime loading, GPU/CPU fallback,
// multi-face detection, and real-time head pose extraction.
// ==============================================================================

import {
  FilesetResolver,
  FaceLandmarker,
  FaceLandmarkerResult,
} from '@mediapipe/tasks-vision';
import {
  estimatePoseFromMatrix,
  estimatePoseFromLandmarks,
  HeadPoseEstimate,
} from './head-pose';

export interface DetectionResult {
  ready: boolean;
  faceCount: number;
  pose: HeadPoseEstimate | null;
  landmarks: Array<{ x: number; y: number; z: number }> | null;
  error?: string;
}

class FaceLandmarkerService {
  private static instance: FaceLandmarkerService | null = null;
  private landmarker: FaceLandmarker | null = null;
  private isInitializing: boolean = false;
  private initError: string | null = null;
  private lastProcessedTimestamp: number = 0;

  public static getInstance(): FaceLandmarkerService {
    if (!FaceLandmarkerService.instance) {
      FaceLandmarkerService.instance = new FaceLandmarkerService();
    }
    return FaceLandmarkerService.instance;
  }

  public isReady(): boolean {
    return this.landmarker !== null;
  }

  public getError(): string | null {
    return this.initError;
  }

  public async initialize(): Promise<boolean> {
    if (this.landmarker) return true;
    if (this.isInitializing) {
      while (this.isInitializing) {
        await new Promise((r) => setTimeout(r, 100));
      }
      return this.landmarker !== null;
    }

    this.isInitializing = true;
    this.initError = null;

    try {
      // 1. Resolve WASM assets (try local /wasm first, fallback to jsdelivr CDN)
      let vision;
      try {
        vision = await FilesetResolver.forVisionTasks('/wasm');
      } catch (wasmErr) {
        console.warn('Không tải được /wasm cục bộ, thử CDN...', wasmErr);
        vision = await FilesetResolver.forVisionTasks(
          'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm'
        );
      }

      // 2. Initialize FaceLandmarker with GPU delegate (fallback to CPU if WebGL fails)
      const modelPath = '/models/face_landmarker.task';
      const cdnModelPath =
        'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task';

      try {
        this.landmarker = await FaceLandmarker.createFromOptions(vision, {
          baseOptions: {
            modelAssetPath: modelPath,
            delegate: 'GPU',
          },
          outputFacialTransformationMatrixes: true,
          outputFaceBlendshapes: false,
          runningMode: 'VIDEO',
          numFaces: 2, // Detect up to 2 faces to reject multiface
          minFaceDetectionConfidence: 0.5,
          minFacePresenceConfidence: 0.5,
          minTrackingConfidence: 0.5,
        });
      } catch (gpuErr) {
        console.warn('GPU delegate không khả dụng, chuyển sang CPU...', gpuErr);
        try {
          this.landmarker = await FaceLandmarker.createFromOptions(vision, {
            baseOptions: {
              modelAssetPath: modelPath,
              delegate: 'CPU',
            },
            outputFacialTransformationMatrixes: true,
            outputFaceBlendshapes: false,
            runningMode: 'VIDEO',
            numFaces: 2,
            minFaceDetectionConfidence: 0.5,
            minFacePresenceConfidence: 0.5,
            minTrackingConfidence: 0.5,
          });
        } catch (cdnFallbackErr) {
          console.warn('Thử tải model từ Google CDN...', cdnFallbackErr);
          this.landmarker = await FaceLandmarker.createFromOptions(vision, {
            baseOptions: {
              modelAssetPath: cdnModelPath,
              delegate: 'CPU',
            },
            outputFacialTransformationMatrixes: true,
            outputFaceBlendshapes: false,
            runningMode: 'VIDEO',
            numFaces: 2,
            minFaceDetectionConfidence: 0.5,
            minFacePresenceConfidence: 0.5,
            minTrackingConfidence: 0.5,
          });
        }
      }

      return true;
    } catch (err: any) {
      console.error('Khởi tạo MediaPipe FaceLandmarker thất bại:', err);
      this.initError = err?.message || 'Không thể tải mô hình MediaPipe FaceLandmarker';
      this.landmarker = null;
      return false;
    } finally {
      this.isInitializing = false;
    }
  }

  public detectForVideo(video: HTMLVideoElement, timestampMs: number): DetectionResult {
    if (!this.landmarker) {
      return {
        ready: false,
        faceCount: 0,
        pose: null,
        landmarks: null,
        error: this.initError || 'Mô hình FaceLandmarker chưa sẵn sàng',
      };
    }

    // MediaPipe requires strictly increasing timestamps in VIDEO mode
    const now = Math.max(timestampMs, this.lastProcessedTimestamp + 1);
    this.lastProcessedTimestamp = now;

    try {
      const result: FaceLandmarkerResult = this.landmarker.detectForVideo(video, now);
      const faceCount = result.faceLandmarks ? result.faceLandmarks.length : 0;

      if (faceCount === 0) {
        return {
          ready: true,
          faceCount: 0,
          pose: null,
          landmarks: null,
        };
      }

      if (faceCount > 1) {
        return {
          ready: true,
          faceCount,
          pose: null,
          landmarks: null,
          error: 'Phát hiện nhiều hơn một khuôn mặt',
        };
      }

      // Exactly 1 face detected!
      const faceLandmarks = result.faceLandmarks[0];
      let pose: HeadPoseEstimate;

      if (
        result.facialTransformationMatrixes &&
        result.facialTransformationMatrixes.length > 0 &&
        result.facialTransformationMatrixes[0].data &&
        result.facialTransformationMatrixes[0].data.length >= 16
      ) {
        // Primary method: 4x4 Transformation Matrix
        pose = estimatePoseFromMatrix(result.facialTransformationMatrixes[0]);
      } else {
        // Fallback method: 3D Facial Landmark Triangulation
        pose = estimatePoseFromLandmarks(faceLandmarks);
      }

      return {
        ready: true,
        faceCount: 1,
        pose,
        landmarks: faceLandmarks,
      };
    } catch (err: any) {
      console.error('Lỗi khi phân tích frame video bằng FaceLandmarker:', err);
      return {
        ready: false,
        faceCount: 0,
        pose: null,
        landmarks: null,
        error: err?.message || 'Lỗi trích xuất landmarks',
      };
    }
  }

  public release(): void {
    if (this.landmarker) {
      try {
        this.landmarker.close();
      } catch (e) {
        console.warn('Lỗi khi đóng FaceLandmarker:', e);
      }
      this.landmarker = null;
    }
  }
}

export const faceLandmarkerService = FaceLandmarkerService.getInstance();
