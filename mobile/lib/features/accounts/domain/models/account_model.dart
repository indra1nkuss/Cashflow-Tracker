class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.accountType,
    required this.initialBalance,
    required this.currentBalance,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.currency = 'IDR',
  });

  final String id;
  final String name;
  final String accountType; // BANK, CASH, EWALLET, INVESTMENT, OTHER
  final double initialBalance;
  final double currentBalance;
  final double totalIncome;
  final double totalExpense;
  final String currency;

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      accountType: json['accountType'] as String? ?? 'BANK',
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'IDR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountType': accountType,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance,
      'currency': currency,
    };
  }
}

