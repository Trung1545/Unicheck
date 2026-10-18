import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_api_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TokenStorage>()) {
      Get.put<TokenStorage>(PlatformTokenStorage(), permanent: true);
    }

    if (!Get.isRegistered<ApiClient>()) {
      Get.put<ApiClient>(
        ApiClient(
          tokenStorage: Get.find<TokenStorage>(),
          onAuthFailure: () {
            if (Get.isRegistered<AuthController>()) {
              Get.find<AuthController>().forceLogout();
            }
          },
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<AuthApiService>()) {
      Get.put<AuthApiService>(
        AuthApiService(apiClient: Get.find<ApiClient>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          authApiService: Get.find<AuthApiService>(),
          tokenStorage: Get.find<TokenStorage>(),
        ),
        permanent: true,
      );
    }
  }
}
