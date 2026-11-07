// API Route Paths
class ApiRoutes {
  ApiRoutes._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Users
  static const String me = '/users/me';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';

  // Accounts
  static const String accounts = '/accounts';
  static String accountById(String id) => '/accounts/$id';

  // Categories
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  // Transactions
  static const String transactions = '/transactions';
  static String transactionById(String id) => '/transactions/$id';

  // Reports
  static const String monthlyReport = '/reports/monthly';

  // Telegram
  static const String telegramLinkStatus = '/telegram/link-status';

  // AI Parser
  static const String aiParse = '/ai-parser/parse';
}

