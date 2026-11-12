import 'package:flutter/foundation.dart';

enum RevelationType { makki, madani }

@immutable
class Surah {
  const Surah({
    required this.number,
    required this.arabicName,
    required this.transliteration,
    required this.verseCount,
    required this.revelationOrder,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    final revelationType = switch (json['revelationType']) {
      'makki' => RevelationType.makki,
      'madani' => RevelationType.madani,
      _ => throw const FormatException('Unknown Surah revelation type.'),
    };

    return Surah(
      number: _requiredInt(json, 'number'),
      arabicName: _requiredString(json, 'arabicName'),
      transliteration: _requiredString(json, 'transliteration'),
      verseCount: _requiredInt(json, 'verseCount'),
      revelationOrder: _requiredInt(json, 'revelationOrder'),
      revelationType: revelationType,
    );
  }

  final int number;
  final String arabicName;
  final String transliteration;
  final int verseCount;
  final int revelationOrder;
  final RevelationType revelationType;

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Surah metadata field "$key" must be an integer.');
    }
    return value;
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Surah metadata field "$key" must be a string.');
    }
    return value;
  }
}
