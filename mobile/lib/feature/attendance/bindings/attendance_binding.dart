import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../controllers/attendance_controller.dart';
import '../services/attendance_api_service.dart';
import '../utils/wifi_validator.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AttendanceApiService>()) {
      final apiClient = Get.isRegistered<ApiClient>()
          ? Get.find<ApiClient>()
          : ApiClient(
              tokenStorage: Get.isRegistered<TokenStorage>()
                  ? Get.find<TokenStorage>()
                  : PlatformTokenStorage(),
            );
      Get.lazyPut<AttendanceApiService>(() => AttendanceApiService(apiClient: apiClient));
    }

    if (!Get.isRegistered<WifiValidator>()) {
      Get.lazyPut<WifiValidator>(() => WifiValidator());
    }

    if (!Get.isRegistered<AttendanceController>()) {
      Get.lazyPut<AttendanceController>(
        () => AttendanceController(
          apiService: Get.find<AttendanceApiService>(),
          wifiValidator: Get.find<WifiValidator>(),
        ),
      );
    }
  }
}
