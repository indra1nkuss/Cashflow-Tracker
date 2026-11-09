import 'package:personal_finance_tracker/features/transactions/domain/models/transaction_model.dart';

class AccountSummaryItem {
  const AccountSummaryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  final String id;
  final String name;
  final String type;
  final double balance;

  factory AccountSummaryItem.fromJson(Map<String, dynamic> json) {
    return AccountSummaryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }
}

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.netSavings,
    required this.accountsSummary,
    required this.recentTransactions,
  });

  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double netSavings;
  final List<AccountSummaryItem> accountsSummary;
  final List<TransactionModel> recentTransactions;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final accountsList = (json['accountsSummary'] as List<dynamic>?) ?? [];
    final recentList = (json['recentTransactions'] as List<dynamic>?) ?? [];

    return DashboardSummaryModel(
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0.0,
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      monthlyExpense: (json['monthlyExpense'] as num?)?.toDouble() ?? 0.0,
      netSavings: (json['netSavings'] as num?)?.toDouble() ?? 0.0,
      accountsSummary: accountsList
          .map((e) => AccountSummaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentTransactions: recentList
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
