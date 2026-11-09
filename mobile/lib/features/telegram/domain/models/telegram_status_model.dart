class TelegramStatusModel {
  const TelegramStatusModel({
    required this.isLinked,
    this.telegramUsername,
    this.firstName,
    this.linkedAt,
  });

  final bool isLinked;
  final String? telegramUsername;
  final String? firstName;
  final DateTime? linkedAt;

  factory TelegramStatusModel.fromJson(Map<String, dynamic> json) {
    return TelegramStatusModel(
      isLinked: json['isLinked'] as bool? ?? false,
      telegramUsername: json['telegramUsername'] as String?,
      firstName: json['firstName'] as String?,
      linkedAt: json['linkedAt'] != null
          ? DateTime.tryParse(json['linkedAt'] as String)
          : null,
    );
  }
}

class TelegramLinkCodeModel {
  const TelegramLinkCodeModel({
    required this.code,
    required this.expiresAt,
  });

  final String code;
  final DateTime expiresAt;

  factory TelegramLinkCodeModel.fromJson(Map<String, dynamic> json) {
    return TelegramLinkCodeModel(
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
