// ==============================================================================
// UniCheck Mobile - Head Pose Evaluator
// Mathematical Head Pose validation for Google ML Kit Face Detection
// Evaluates Euler Angles (Y: Yaw, X: Pitch, Z: Roll) with zero tolerance for
// looking-straight false positives.
// ==============================================================================

enum EnrollmentStep {
  frontal,
  left,
  right,
}

class HeadPoseValidation {
  final bool isValid;
  final String guideMessage;
  final String? warningMessage;

  const HeadPoseValidation({
    required this.isValid,
    required this.guideMessage,
    this.warningMessage,
  });
}

class HeadPoseEvaluator {
  /// Evaluates head pose using ML Kit Euler Angles (Y = Yaw, X = Pitch, Z = Roll)
  /// Yaw sign convention for front camera:
  /// - Yaw > 0: Turned to Left
  /// - Yaw < 0: Turned to Right
  /// - |Yaw| <= 8°: Frontal
  static HeadPoseValidation validate({
    required EnrollmentStep step,
    required double? eulerY,
    required double? eulerX,
    required double? eulerZ,
    required int faceCount,
  }) {
    if (faceCount == 0) {
      return const HeadPoseValidation(
        isValid: false,
        guideMessage: 'Không phát hiện khuôn mặt',
        warningMessage: 'Vui lòng căn chỉnh khuôn mặt vào giữa khung Oval',
      );
    }

    if (faceCount > 1) {
      return const HeadPoseValidation(
        isValid: false,
        guideMessage: 'Phát hiện nhiều khuôn mặt',
        warningMessage: 'Chỉ cho phép duy nhất một người trong khung hình',
      );
    }

    if (eulerY == null) {
      return const HeadPoseValidation(
        isValid: false,
        guideMessage: 'Đang ước lượng góc mặt...',
      );
    }

    // Roll check (neck tilt sideways)
    if (eulerZ != null && eulerZ.abs() > 15.0) {
      return const HeadPoseValidation(
        isValid: false,
        guideMessage: 'Đang nghiêng cổ',
        warningMessage: 'Giữ thẳng cổ, không nghiêng đầu sang một bên',
      );
    }

    // Pitch check (nodding up/down)
    if (eulerX != null && eulerX.abs() > 15.0) {
      return HeadPoseValidation(
        isValid: false,
        guideMessage: eulerX > 0 ? 'Đang ngửa đầu' : 'Đang cúi đầu',
        warningMessage: 'Giữ mặt ngang tầm camera, không cúi hoặc ngửa',
      );
    }

    switch (step) {
      case EnrollmentStep.frontal:
        if (eulerY.abs() <= 8.0) {
          return const HeadPoseValidation(
            isValid: true,
            guideMessage: 'Tốt! Giữ nguyên góc nhìn thẳng...',
          );
        } else if (eulerY > 8.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Mặt đang quay sang trái',
            warningMessage: 'Vui lòng nhìn THẲNG chính diện vào camera',
          );
        } else {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Mặt đang quay sang phải',
            warningMessage: 'Vui lòng nhìn THẲNG chính diện vào camera',
          );
        }

      case EnrollmentStep.left:
        // Turning Left: requires eulerY between 11° and 28°
        if (eulerY.abs() <= 8.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Bạn đang nhìn thẳng',
            warningMessage: 'Vui lòng quay nhẹ đầu sang TRÁI (khoảng 15°)',
          );
        } else if (eulerY < -8.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Bạn đang quay sang PHẢI',
            warningMessage: 'Vui lòng quay ngược lại sang phía TRÁI',
          );
        } else if (eulerY < 11.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Chưa đủ góc quay trái',
            warningMessage: 'Quay thêm một chút nữa sang bên trái',
          );
        } else if (eulerY > 28.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Quay trái quá nhiều',
            warningMessage: 'Quay lại một chút, chỉ cần nghiêng nhẹ 15°',
          );
        } else {
          return const HeadPoseValidation(
            isValid: true,
            guideMessage: 'Tốt! Giữ nguyên góc nghiêng trái...',
          );
        }

      case EnrollmentStep.right:
        // Turning Right: requires eulerY between -28° and -11°
        if (eulerY.abs() <= 8.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Bạn đang nhìn thẳng',
            warningMessage: 'Vui lòng quay nhẹ đầu sang PHẢI (khoảng 15°)',
          );
        } else if (eulerY > 8.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Bạn đang quay sang TRÁI',
            warningMessage: 'Vui lòng quay ngược lại sang phía PHẢI',
          );
        } else if (eulerY > -11.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Chưa đủ góc quay phải',
            warningMessage: 'Quay thêm một chút nữa sang bên phải',
          );
        } else if (eulerY < -28.0) {
          return const HeadPoseValidation(
            isValid: false,
            guideMessage: 'Quay phải quá nhiều',
            warningMessage: 'Quay lại một chút, chỉ cần nghiêng nhẹ 15°',
          );
        } else {
          return const HeadPoseValidation(
            isValid: true,
            guideMessage: 'Tốt! Giữ nguyên góc nghiêng phải...',
          );
        }
    }
  }
}
