import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../controllers/dashboard_controller.dart';
import '../services/dashboard_api_service.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DashboardApiService>()) {
      Get.lazyPut<DashboardApiService>(
        () => DashboardApiService(
          apiClient: Get.isRegistered<ApiClient>()
              ? Get.find<ApiClient>()
              : ApiClient(
                  tokenStorage: Get.isRegistered<TokenStorage>()
                      ? Get.find<TokenStorage>()
                      : PlatformTokenStorage(),
                ),
        ),
      );
    }

    if (!Get.isRegistered<DashboardController>()) {
      Get.lazyPut<DashboardController>(
        () => DashboardController(
          apiService: Get.find<DashboardApiService>(),
        ),
      );
    }
  }
}
