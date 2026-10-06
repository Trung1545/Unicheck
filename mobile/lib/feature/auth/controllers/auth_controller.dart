import 'package:get/get.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  bool get isAuthenticated => user.value != null;

  Future<bool> login(String username, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Simulated login logic until full API integration
      await Future.delayed(const Duration(milliseconds: 600));
      user.value = UserModel(
        id: 1,
        username: username,
        fullName: 'Nguyễn Văn A',
        email: '$username@unicheck.edu.vn',
        role: 'STUDENT',
        faceDataStatus: 'ACTIVE',
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    user.value = null;
    Get.offAllNamed('/login');
  }
}
