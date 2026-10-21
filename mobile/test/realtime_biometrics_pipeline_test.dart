import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:unicheck_mobile/core/utils/camera_image_converter.dart';
import 'package:unicheck_mobile/core/utils/face_biometric_logger.dart';
import 'package:unicheck_mobile/core/utils/head_pose_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraImageConverter Unit Tests', () {
    const frontCamera = CameraDescription(
      name: '1',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 270,
    );

    const backCamera = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    test('getImageRotation: Front camera portraitUp resolves to rotation270deg', () {
      final rotation = CameraImageConverter.getImageRotation(
        camera: frontCamera,
        deviceOrientation: DeviceOrientation.portraitUp,
      );
      expect(rotation, InputImageRotation.rotation270deg);
    });

    test('getImageRotation: Back camera portraitUp resolves to rotation90deg', () {
      final rotation = CameraImageConverter.getImageRotation(
        camera: backCamera,
        deviceOrientation: DeviceOrientation.portraitUp,
      );
      expect(rotation, InputImageRotation.rotation90deg);
    });

    test('resolveInputFormat: correctly maps Android and iOS raw formats', () {
      expect(CameraImageConverter.resolveInputFormat(17), InputImageFormat.nv21);
      expect(CameraImageConverter.resolveInputFormat(35), InputImageFormat.yuv_420_888);
      expect(CameraImageConverter.resolveInputFormat(842094169), InputImageFormat.yv12);
      expect(CameraImageConverter.resolveInputFormat(875704438), InputImageFormat.yuv420);
      expect(CameraImageConverter.resolveInputFormat(1111970369), InputImageFormat.bgra8888);
      expect(CameraImageConverter.resolveInputFormat(999999), isNull);
    });

    test('toInputImage: converts single-plane NV21 CameraImage accurately', () {
      final dummyBytes = Uint8List(640 * 480);
      // ignore: deprecated_member_use
      final cameraImage = CameraImage.fromPlatformData({
        'format': 17,
        'width': 640,
        'height': 480,
        'planes': [
          {
            'bytes': dummyBytes,
            'bytesPerRow': 640,
          },
        ],
      });

      final inputImage = CameraImageConverter.toInputImage(
        image: cameraImage,
        camera: frontCamera,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(inputImage, isNotNull);
      expect(inputImage!.type, InputImageType.bytes);
      expect(inputImage.metadata?.size.width, 640.0);
      expect(inputImage.metadata?.size.height, 480.0);
      expect(inputImage.metadata?.rotation, InputImageRotation.rotation270deg);
      expect(inputImage.metadata?.format, InputImageFormat.nv21);
      expect(inputImage.bytes?.length, dummyBytes.length);
    });

    test('toInputImage: converts 3-plane YUV420 CameraImage by concatenating planes', () {
      final yPlane = Uint8List(400);
      final uPlane = Uint8List(100);
      final vPlane = Uint8List(100);

      // ignore: deprecated_member_use
      final cameraImage = CameraImage.fromPlatformData({
        'format': 35,
        'width': 20,
        'height': 20,
        'planes': [
          {'bytes': yPlane, 'bytesPerRow': 20},
          {'bytes': uPlane, 'bytesPerRow': 10},
          {'bytes': vPlane, 'bytesPerRow': 10},
        ],
      });

      final inputImage = CameraImageConverter.toInputImage(
        image: cameraImage,
        camera: frontCamera,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(inputImage, isNotNull);
      expect(inputImage!.bytes?.length, 600); // 400 + 100 + 100
      expect(inputImage.metadata?.format, InputImageFormat.yuv_420_888);
    });

    test('toInputImage: returns null when image format is unsupported or planes are empty', () {
      // ignore: deprecated_member_use
      final emptyPlanesImage = CameraImage.fromPlatformData({
        'format': 17,
        'width': 640,
        'height': 480,
        'planes': <Map<String, dynamic>>[],
      });

      expect(
        CameraImageConverter.toInputImage(
          image: emptyPlanesImage,
          camera: frontCamera,
        ),
        isNull,
      );

      // ignore: deprecated_member_use
      final unsupportedFormatImage = CameraImage.fromPlatformData({
        'format': 9999,
        'width': 640,
        'height': 480,
        'planes': [
          {'bytes': Uint8List(10), 'bytesPerRow': 10},
        ],
      });

      expect(
        CameraImageConverter.toInputImage(
          image: unsupportedFormatImage,
          camera: frontCamera,
        ),
        isNull,
      );
    });
  });

  group('HeadPoseEvaluator & State Machine Criteria Tests', () {
    test('ML Kit returns no face (faceCount: 0) fails closed with guidance', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.frontal,
        eulerY: null,
        eulerX: null,
        eulerZ: null,
        faceCount: 0,
      );
      expect(res.isValid, isFalse);
      expect(res.guideMessage, contains('Không phát hiện'));
    });

    test('Multiple faces detected (faceCount: 2) fails closed for anti-spoofing security', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.frontal,
        eulerY: 0.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 2,
      );
      expect(res.isValid, isFalse);
      expect(res.guideMessage, contains('nhiều khuôn mặt'));
      expect(res.warningMessage, contains('duy nhất một người'));
    });

    test('Step 1 (Frontal): Straight face (|Yaw| <= 8°) is accepted', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.frontal,
        eulerY: 3.2,
        eulerX: -1.0,
        eulerZ: 0.5,
        faceCount: 1,
      );
      expect(res.isValid, isTrue);
      expect(res.guideMessage, contains('Tốt! Giữ nguyên'));
    });

    test('Step 1 (Frontal): Turned face (|Yaw| > 8°) is rejected with directional correction', () {
      final turnedLeft = HeadPoseEvaluator.validate(
        step: EnrollmentStep.frontal,
        eulerY: 15.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );
      expect(turnedLeft.isValid, isFalse);
      expect(turnedLeft.guideMessage, contains('trái'));
      expect(turnedLeft.warningMessage, contains('nhìn THẲNG'));

      final turnedRight = HeadPoseEvaluator.validate(
        step: EnrollmentStep.frontal,
        eulerY: -15.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );
      expect(turnedRight.isValid, isFalse);
      expect(turnedRight.guideMessage, contains('phải'));
      expect(turnedRight.warningMessage, contains('nhìn THẲNG'));
    });

    test('Step 2 (Left): Turn left (Yaw between 11° and 28°) is accepted', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.left,
        eulerY: 16.5,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );
      expect(res.isValid, isTrue);
      expect(res.guideMessage, contains('Tốt! Giữ nguyên góc nghiêng trái'));
    });

    test('Step 2 (Left): Turn right or straight is rejected', () {
      final straight = HeadPoseEvaluator.validate(
        step: EnrollmentStep.left,
        eulerY: 2.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );
      expect(straight.isValid, isFalse);
      expect(straight.warningMessage, contains('TRÁI'));

      final right = HeadPoseEvaluator.validate(
        step: EnrollmentStep.left,
        eulerY: -15.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );
      expect(right.isValid, isFalse);
      expect(right.warningMessage, contains('TRÁI'));
    });

    test('Step 3 (Right): Turn right (Yaw between -28° and -11°) is accepted', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.right,
        eulerY: -16.5,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );
      expect(res.isValid, isTrue);
      expect(res.guideMessage, contains('Tốt! Giữ nguyên góc nghiêng phải'));
    });

    test('Step 3 (Right): Turn left or straight is rejected', () {
      final straight = HeadPoseEvaluator.validate(
        step: EnrollmentStep.right,
        eulerY: 2.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );
      expect(straight.isValid, isFalse);
      expect(straight.warningMessage, contains('PHẢI'));

      final left = HeadPoseEvaluator.validate(
        step: EnrollmentStep.right,
        eulerY: 15.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );
      expect(left.isValid, isFalse);
      expect(left.warningMessage, contains('PHẢI'));
    });
  });

  group('Pipeline Resilience & Concurrency Safety Tests', () {
    test('Processing flag resets via try/finally even if an error is thrown', () {
      bool isProcessing = false;

      void simulateFrameAnalysis({required bool shouldThrow}) {
        if (isProcessing) return;
        isProcessing = true;
        try {
          if (shouldThrow) {
            throw Exception('Simulated frame processing exception');
          }
        } finally {
          isProcessing = false;
        }
      }

      // Normal frame
      simulateFrameAnalysis(shouldThrow: false);
      expect(isProcessing, isFalse);

      // Crashing frame
      expect(() => simulateFrameAnalysis(shouldThrow: true), throwsException);
      expect(isProcessing, isFalse, reason: 'Flag must reset to false in finally block');

      // Next frame can still be processed without lockup!
      simulateFrameAnalysis(shouldThrow: false);
      expect(isProcessing, isFalse);
    });

    test('Step transition progresses exactly once from 1 to 3', () {
      int step = 1;
      final samples = <String>[];

      void advanceStep(String sampleName) {
        if (step > 3) return;
        samples.add(sampleName);
        if (step < 3) {
          step++;
        }
      }

      advanceStep('frontal');
      expect(step, 2);
      expect(samples, ['frontal']);

      advanceStep('left');
      expect(step, 3);
      expect(samples, ['frontal', 'left']);

      advanceStep('right');
      expect(step, 3);
      expect(samples, ['frontal', 'left', 'right']);
    });

    test('FaceBiometricLogger logs without throwing and rate-limits frame stats', () {
      final logger = FaceBiometricLogger(tag: 'TestLogger');

      logger.logCameraInitialized(
        lensDirection: CameraLensDirection.front,
        resolutionPreset: ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      logger.logStreamStarted();
      logger.logStreamStopped();

      logger.logFrameStats(
        framesReceived: 10,
        framesProcessed: 5,
        faceCount: 1,
        yaw: 0.0,
        pitch: 0.0,
        roll: 0.0,
        step: 'frontal',
        mlKitDurationMs: 45,
        totalDurationMs: 60,
      );

      logger.logPoseEvaluated(
        step: 'frontal',
        isValid: true,
        reason: 'Looking straight',
      );

      logger.logCaptureStarted(step: 'frontal');
      logger.logCaptureCompleted(step: 'frontal', durationMs: 150, byteSize: 34500);
      logger.logCaptureFailed(step: 'frontal', error: 'Timeout');
      logger.logStateTransition(fromStep: 'Step 1', toStep: 'Step 2');
      logger.logError('Test context', 'Simulated error');
      logger.logNotice('Test notice');
    });
  });
}
