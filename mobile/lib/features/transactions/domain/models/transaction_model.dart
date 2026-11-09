class TransactionAccountInfo {
  const TransactionAccountInfo({
    required this.id,
    required this.name,
    this.accountType,
  });

  final String id;
  final String name;
  final String? accountType;

  factory TransactionAccountInfo.fromJson(Map<String, dynamic> json) {
    return TransactionAccountInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      accountType: json['accountType'] as String?,
    );
  }
}

class TransactionCategoryInfo {
  const TransactionCategoryInfo({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  final String id;
  final String name;
  final String? icon;
  final String? color;

  factory TransactionCategoryInfo.fromJson(Map<String, dynamic> json) {
    return TransactionCategoryInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.source,
    this.notes,
    this.account,
    this.category,
  });

  final String id;
  final String type; // INCOME or EXPENSE
  final double amount;
  final String description;
  final DateTime transactionDate;
  final String source;
  final String? notes;
  final TransactionAccountInfo? account;
  final TransactionCategoryInfo? category;

  bool get isIncome => type == 'INCOME';
  bool get isExpense => type == 'EXPENSE';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      notes: json['notes'] as String?,
      source: json['source'] as String? ?? 'MOBILE',
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      account: json['account'] != null
          ? TransactionAccountInfo.fromJson(json['account'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? TransactionCategoryInfo.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

