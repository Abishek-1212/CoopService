class FirebaseErrorMapper {
  static String getMessage(dynamic error) {
    if (error is String) return error;
    final String errorStr = error.toString();

    if (errorStr.contains('user-not-found')) {
      return 'No user found with this email address. Please check your email or create an account.';
    } else if (errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again.';
    } else if (errorStr.contains('email-already-in-use')) {
      return 'An account already exists with this email address.';
    } else if (errorStr.contains('invalid-email')) {
      return 'The email address format is invalid.';
    } else if (errorStr.contains('weak-password')) {
      return 'The password provided is too weak. Please use at least 6 characters.';
    } else if (errorStr.contains('user-disabled')) {
      return 'This user account has been disabled. Please contact support.';
    } else if (errorStr.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorStr.contains('too-many-requests')) {
      return 'Too many unsuccessful attempts. Please wait a moment and try again.';
    } else if (errorStr.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Please contact administrator.';
    }

    // Default friendly message
    return 'An unexpected error occurred. Please try again.';
  }
}
