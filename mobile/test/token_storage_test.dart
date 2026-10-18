import 'package:flutter_test/flutter_test.dart';
import 'package:unicheck_mobile/core/storage/token_storage.dart';

void main() {
  group('TokenStorage Platform Adapter Tests', () {
    late TokenStorage storage;

    setUp(() {
      storage = PlatformTokenStorage();
    });

    test('Initial state: hasAccessToken returns false and tokens are null', () async {
      await storage.clearTokens();
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('saveTokens persists both access and refresh tokens', () async {
      await storage.saveTokens(
        accessToken: 'mock_jwt_access_token_123',
        refreshToken: 'mock_uuid_refresh_token_456',
      );

      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.getAccessToken(), equals('mock_jwt_access_token_123'));
      expect(await storage.getRefreshToken(), equals('mock_uuid_refresh_token_456'));
    });

    test('clearTokens purges both tokens and resets hasAccessToken to false', () async {
      await storage.saveTokens(
        accessToken: 'access_to_clear',
        refreshToken: 'refresh_to_clear',
      );
      expect(await storage.hasAccessToken(), isTrue);

      await storage.clearTokens();

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });
}
