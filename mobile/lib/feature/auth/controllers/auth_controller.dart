import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

class AuthController extends GetxController {
  final AuthApiService authApiService;
  final TokenStorage tokenStorage;

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isRestoringSession = false.obs;

  AuthController({
    AuthApiService? authApiService,
    TokenStorage? tokenStorage,
  })  : authApiService = authApiService ??
            AuthApiService(
              apiClient: Get.isRegistered<ApiClient>()
                  ? Get.find<ApiClient>()
                  : ApiClient(
                      tokenStorage: tokenStorage ?? PlatformTokenStorage(),
                    ),
            ),
        tokenStorage = tokenStorage ??
            (Get.isRegistered<TokenStorage>()
                ? Get.find<TokenStorage>()
                : PlatformTokenStorage());

  bool get isAuthenticated => user.value != null;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      final hasToken = await tokenStorage.hasAccessToken();
      if (!hasToken) return;

      isRestoringSession.value = true;
      final profile = await authApiService.getMe();
      user.value = profile;
      _navigateToRoleShell(profile.role);
    } catch (_) {
      await tokenStorage.clearTokens();
      user.value = null;
    } finally {
      isRestoringSession.value = false;
    }
  }

  Future<bool> login(String username, String password) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      errorMessage.value = 'Vui lòng nhập tên đăng nhập và mật khẩu';
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await authApiService.login(
        username: cleanUsername,
        password: cleanPassword,
      );

      // Persist real tokens
      await tokenStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );

      user.value = result.user;
      _navigateToRoleShell(result.user.role);
      return true;
    } catch (e) {
      errorMessage.value = ApiClient.extractErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateToRoleShell(String role) {
    if (Get.testMode && Get.key.currentState == null) {
      return;
    }
    switch (role.toUpperCase()) {
      case 'ADMIN':
        Get.offAllNamed(AppRoutes.admin);
        break;
      case 'LECTURER':
        Get.offAllNamed(AppRoutes.lecturer);
        break;
      case 'STUDENT':
      default:
        Get.offAllNamed(AppRoutes.student);
        break;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await authApiService.logout();
    } catch (_) {
      // Best-effort server logout
    } finally {
      await tokenStorage.clearTokens();
      user.value = null;
      errorMessage.value = '';
      isLoading.value = false;
      if (!Get.testMode || Get.key.currentState != null) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  void forceLogout() {
    tokenStorage.clearTokens();
    user.value = null;
    errorMessage.value = 'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại';
    if (!Get.testMode || Get.key.currentState != null) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
