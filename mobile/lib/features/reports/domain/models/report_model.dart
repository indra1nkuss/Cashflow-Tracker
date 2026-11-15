class CategoryBreakdownItem {
  const CategoryBreakdownItem({
    required this.name,
    required this.type,
    required this.total,
    this.color,
  });

  final String name;
  final String type;
  final double total;
  final String? color;

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      name: json['name'] as String,
      type: json['type'] as String,
      total: (json['total'] as num).toDouble(),
      color: json['color'] as String?,
    );
  }
}

class MonthlyReportModel {
  const MonthlyReportModel({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashflow,
    required this.categoryBreakdown,
  });

  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double netCashflow;
  final List<CategoryBreakdownItem> categoryBreakdown;

  List<CategoryBreakdownItem> get expenseBreakdown =>
      categoryBreakdown.where((c) => c.type == 'EXPENSE').toList();

  List<CategoryBreakdownItem> get incomeBreakdown =>
      categoryBreakdown.where((c) => c.type == 'INCOME').toList();

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>;
    final breakdown = (json['categoryBreakdown'] as List<dynamic>?) ?? [];

    return MonthlyReportModel(
      year: period['year'] as int,
      month: period['month'] as int,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      netCashflow: (json['netCashflow'] as num?)?.toDouble() ?? 0.0,
      categoryBreakdown: breakdown
          .map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

