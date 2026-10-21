import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// UniCheck Biometric Debug Logger
/// Provides structured, rate-limited debug instrumentation for real-time Face-ID.
/// PRIVACY POLICY: Under no circumstances are raw face images, base64 data,
/// or biometric embedding vectors logged.
class FaceBiometricLogger {
  final String tag;
  DateTime _lastStatsLogTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastLoggedFaceCount = -1;
  String _lastLoggedStep = '';

  FaceBiometricLogger({this.tag = 'FaceBiometric'});

  void logCameraInitialized({
    required CameraLensDirection lensDirection,
    required ResolutionPreset resolutionPreset,
    required ImageFormatGroup imageFormatGroup,
  }) {
    if (!kDebugMode) return;
    debugPrint('[$tag] Camera initialized: lens=$lensDirection, preset=$resolutionPreset, format=$imageFormatGroup');
  }

  void logStreamStarted() {
    if (!kDebugMode) return;
    debugPrint('[$tag] Image stream started successfully.');
  }

  void logStreamStopped() {
    if (!kDebugMode) return;
    debugPrint('[$tag] Image stream stopped.');
  }

  void logFrameStats({
    required int framesReceived,
    required int framesProcessed,
    required int faceCount,
    double? yaw,
    double? pitch,
    double? roll,
    required String step,
    required int mlKitDurationMs,
    required int totalDurationMs,
  }) {
    if (!kDebugMode) return;
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastStatsLogTime).inMilliseconds;

    // Rate-limit frame stats to at most once per 1000ms unless face count or step changed
    final stateChanged = faceCount != _lastLoggedFaceCount || step != _lastLoggedStep;
    if (elapsedMs < 1000 && !stateChanged) {
      return;
    }

    _lastStatsLogTime = now;
    _lastLoggedFaceCount = faceCount;
    _lastLoggedStep = step;

    final yawStr = yaw != null ? '${yaw.toStringAsFixed(1)}°' : 'N/A';
    final pitchStr = pitch != null ? '${pitch.toStringAsFixed(1)}°' : 'N/A';
    final rollStr = roll != null ? '${roll.toStringAsFixed(1)}°' : 'N/A';

    debugPrint(
      '[$tag] Frames: recv=$framesReceived, proc=$framesProcessed | '
      'Step=$step | Faces=$faceCount | Pose(Yaw=$yawStr, Pitch=$pitchStr, Roll=$rollStr) | '
      'MLKit=${mlKitDurationMs}ms, Frame=${totalDurationMs}ms',
    );
  }

  void logPoseEvaluated({
    required String step,
    required bool isValid,
    required String reason,
    double? yaw,
    double? pitch,
    double? roll,
  }) {
    if (!kDebugMode) return;
    final status = isValid ? 'ACCEPTED' : 'REJECTED';
    final angles = yaw != null
        ? ' [Yaw=${yaw.toStringAsFixed(1)}°, Pitch=${pitch?.toStringAsFixed(1)}°, Roll=${roll?.toStringAsFixed(1)}°]'
        : '';
    debugPrint('[$tag] Pose $status for step [$step]: $reason$angles');
  }

  void logCaptureStarted({required String step}) {
    if (!kDebugMode) return;
    debugPrint('[$tag] Capture STARTED for step [$step] (coordinated with image stream)');
  }

  void logCaptureCompleted({
    required String step,
    required int durationMs,
    required int byteSize,
  }) {
    if (!kDebugMode) return;
    debugPrint('[$tag] Capture COMPLETED for step [$step] in ${durationMs}ms (size: ${(byteSize / 1024).toStringAsFixed(1)} KB)');
  }

  void logCaptureFailed({required String step, required dynamic error}) {
    if (!kDebugMode) return;
    debugPrint('[$tag] Capture FAILED for step [$step]: $error');
  }

  void logStateTransition({required String fromStep, required String toStep}) {
    if (!kDebugMode) return;
    debugPrint('[$tag] State Transition: $fromStep -> $toStep');
  }

  void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[$tag] ERROR in $context: $error');
    if (stackTrace != null) {
      debugPrint('[$tag] Stack trace: $stackTrace');
    }
  }

  void logNotice(String notice) {
    if (!kDebugMode) return;
    debugPrint('[$tag] NOTICE: $notice');
  }
}
