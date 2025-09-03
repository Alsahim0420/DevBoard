import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferences SignOut Tests', () {
    test('should clear SharedPreferences keys', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_token',
        'uid': 'test_uid',
        'user_email': 'test@example.com',
        'user_name': 'test_user',
      });

      final prefs = await SharedPreferences.getInstance();

      // Verify values are set
      expect(prefs.getString('auth_token'), equals('test_token'));
      expect(prefs.getString('uid'), equals('test_uid'));
      expect(prefs.getString('user_email'), equals('test@example.com'));
      expect(prefs.getString('user_name'), equals('test_user'));

      // Act - Simulate signOut clearing
      await prefs.remove('auth_token');
      await prefs.remove('uid');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.clear();

      // Assert
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('uid'), isNull);
      expect(prefs.getString('user_email'), isNull);
      expect(prefs.getString('user_name'), isNull);
      expect(prefs.getKeys(), isEmpty);
    });

    test('should handle empty SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Act & Assert
      expect(prefs.getKeys(), isEmpty);
      expect(prefs.getString('auth_token'), isNull);
    });
  });
}
