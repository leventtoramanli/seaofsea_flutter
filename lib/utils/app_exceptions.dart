// lib/utils/app_exceptions.dart
class EmailVerificationRequired implements Exception {
  final String message;
  EmailVerificationRequired(
      [this.message =
          'Email verification is required to perform this action.']);
  @override
  String toString() => message;
}
