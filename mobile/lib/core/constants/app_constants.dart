import 'package:flutter/foundation.dart';

// API & Network
String get kApiBaseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;

  // Default to localhost:5000 for:
  // - Web (Chrome / Edge)
  // - Desktop (Windows / macOS / Linux)
  // - Android physical devices connected via USB (adb reverse tcp:5000 tcp:5000)
  return 'http://localhost:5000/api';
}
const Duration kConnectTimeout = Duration(seconds: 15);
const Duration kReceiveTimeout = Duration(seconds: 30);

// App Info
const String kAppName = 'Personal Finance Tracker';
const String kAppVersion = '1.0.0';

// Storage Keys
const String kTokenKey = 'auth_token';
const String kUserKey = 'current_user';

// Date Formats
const String kDateFormat = 'dd/MM/yyyy';
const String kDateTimeFormat = 'dd/MM/yyyy HH:mm';
const String kMonthYearFormat = 'MMMM yyyy';

// Currency
const String kCurrencyLocale = 'id_ID';
const String kCurrencySymbol = 'Rp';

// Pagination
const int kDefaultPageSize = 20;

