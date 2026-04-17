/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'NexChat';
  static const String packageName = 'com.nexchat.app';
  static const String appVersion = '1.0.0';

  // Media limits
  static const int maxImageSizeMB = 16;
  static const int maxVideoSizeMB = 100;
  static const int maxDocSizeMB = 100;
  static const int maxGroupMembers = 1024;
  static const int maxChannelMembers = 200000;

  // Status / Stories
  static const int statusExpirationHours = 24;
  static const int maxStatusTextLength = 700;

  // Messages
  static const int maxMessageLength = 4096;
  static const int messagePageSize = 30;

  // Encryption
  static const int rsaKeySize = 2048;
  static const int aesKeySize = 256;

  // Timeouts
  static const Duration otpTimeout = Duration(seconds: 60);
  static const Duration typingTimeout = Duration(seconds: 3);
  static const Duration callRingTimeout = Duration(seconds: 30);
}
