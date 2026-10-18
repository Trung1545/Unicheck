import 'package:flutter_test/flutter_test.dart';
import 'package:unicheck_mobile/core/utils/head_pose_evaluator.dart';

void main() {
  group('Flutter HeadPoseEvaluator Tests', () {
    test('Frontal step: Looking straight (|eulerY| <= 8) passes', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.frontal,
        eulerY: 2.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );

      expect(res.isValid, true);
      expect(res.guideMessage, contains('nhìn thẳng'));
    });

    test('Left step: Looking straight fails and instructs to turn left', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.left,
        eulerY: 1.5,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );

      expect(res.isValid, false);
      expect(res.guideMessage, contains('nhìn thẳng'));
      expect(res.warningMessage, contains('TRÁI'));
    });

    test('Left step: Turned right (negative eulerY) fails and instructs to turn left', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.left,
        eulerY: -15.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );

      expect(res.isValid, false);
      expect(res.guideMessage, contains('PHẢI'));
      expect(res.warningMessage, contains('TRÁI'));
    });

    test('Left step: Turned left (16°) passes', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.left,
        eulerY: 16.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );

      expect(res.isValid, true);
      expect(res.guideMessage, contains('nghiêng trái'));
    });

    test('Right step: Still holding left (16°) fails and instructs to turn right', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.right,
        eulerY: 16.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );

      expect(res.isValid, false);
      expect(res.guideMessage, contains('TRÁI'));
      expect(res.warningMessage, contains('PHẢI'));
    });

    test('Right step: Turned right (-16°) passes', () {
      final res = HeadPoseEvaluator.validate(
        step: EnrollmentStep.right,
        eulerY: -16.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 1,
      );

      expect(res.isValid, true);
      expect(res.guideMessage, contains('nghiêng phải'));
    });

    test('Zero faces or multiple faces fail closed', () {
      final noFace = HeadPoseEvaluator.validate(
        step: EnrollmentStep.frontal,
        eulerY: 0.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 0,
      );
      expect(noFace.isValid, false);

      final multiFace = HeadPoseEvaluator.validate(
        step: EnrollmentStep.frontal,
        eulerY: 0.0,
        eulerX: 0.0,
        eulerZ: 0.0,
        faceCount: 2,
      );
      expect(multiFace.isValid, false);
    });

    test('Excessive neck tilt (Roll > 15°) fails', () {
      final rollFail = HeadPoseEvaluator.validate(
        step: EnrollmentStep.left,
        eulerY: 16.0,
        eulerX: 0.0,
        eulerZ: 20.0,
        faceCount: 1,
      );
      expect(rollFail.isValid, false);
      expect(rollFail.guideMessage, contains('nghiêng cổ'));
    });
  });
}
