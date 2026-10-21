import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// UniCheck CameraImage to ML Kit InputImage Converter
/// Handles Android (NV21, YUV_420_888) and iOS (BGRA8888, YUV420) formats with proper sensor rotation.
class CameraImageConverter {
  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Computes ML Kit [InputImageRotation] based on camera sensor orientation and device orientation.
  static InputImageRotation? getImageRotation({
    required CameraDescription camera,
    DeviceOrientation? deviceOrientation,
  }) {
    final sensorOrientation = camera.sensorOrientation;
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      // Android and standard camera orientation compensation
      var rotationCompensation =
          _orientations[deviceOrientation ?? DeviceOrientation.portraitUp] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        // Front-facing camera sensor rotation compensation
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // Back-facing camera sensor rotation compensation
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      return InputImageRotationValue.fromRawValue(rotationCompensation);
    }
  }

  /// Resolves the raw platform image format into a supported [InputImageFormat].
  static InputImageFormat? resolveInputFormat(int rawFormat) {
    final format = InputImageFormatValue.fromRawValue(rawFormat);
    if (format != null) return format;

    if (rawFormat == 17) return InputImageFormat.nv21;
    if (rawFormat == 35) return InputImageFormat.yuv_420_888;
    if (rawFormat == 842094169) return InputImageFormat.yv12;
    if (rawFormat == 875704438) return InputImageFormat.yuv420;
    if (rawFormat == 1111970369) return InputImageFormat.bgra8888;
    return null;
  }

  /// Converts a [CameraImage] into an [InputImage] ready for ML Kit Face Detection.
  static InputImage? toInputImage({
    required CameraImage image,
    required CameraDescription camera,
    DeviceOrientation? deviceOrientation,
  }) {
    final rotation = getImageRotation(
      camera: camera,
      deviceOrientation: deviceOrientation,
    );
    if (rotation == null) return null;

    final format = resolveInputFormat(image.format.raw);
    if (format == null) return null;

    // Platform format validation
    if (Platform.isIOS) {
      if (format != InputImageFormat.bgra8888 &&
          format != InputImageFormat.yuv420) {
        return null;
      }
    } else {
      if (format != InputImageFormat.nv21 &&
          format != InputImageFormat.yuv_420_888 &&
          format != InputImageFormat.yv12) {
        return null;
      }
    }

    if (image.planes.isEmpty) return null;

    final Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else {
      final builder = BytesBuilder(copy: false);
      for (final plane in image.planes) {
        builder.add(plane.bytes);
      }
      bytes = builder.toBytes();
    }

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }
}
