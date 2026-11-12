import 'package:flutter/foundation.dart';

@immutable
class QuranReciter {
  const QuranReciter({
    required this.identifier,
    required this.arabicName,
    required this.englishName,
    required this.bitrateKbps,
    required this.verifiedAyahCount,
  });

  factory QuranReciter.fromJson(Map<String, dynamic> json) {
    final identifier = json['identifier'];
    final arabicName = json['arabicName'];
    final englishName = json['englishName'];
    final bitrateKbps = json['bitrateKbps'];
    final verifiedAyahCount = json['verifiedAyahCount'];
    if (identifier is! String || identifier.isEmpty) {
      throw const FormatException(
        'Reciter identifier must be a non-empty string.',
      );
    }
    if (arabicName is! String || arabicName.isEmpty) {
      throw const FormatException(
        'Reciter Arabic name must be a non-empty string.',
      );
    }
    if (englishName is! String || englishName.isEmpty) {
      throw const FormatException(
        'Reciter English name must be a non-empty string.',
      );
    }
    if (bitrateKbps is! int || bitrateKbps <= 0) {
      throw const FormatException(
        'Reciter bitrate must be a positive integer.',
      );
    }
    if (verifiedAyahCount is! int || verifiedAyahCount != 6236) {
      throw const FormatException(
        'Each listed reciter must have all 6,236 ayahs verified.',
      );
    }

    return QuranReciter(
      identifier: identifier,
      arabicName: arabicName,
      englishName: englishName,
      bitrateKbps: bitrateKbps,
      verifiedAyahCount: verifiedAyahCount,
    );
  }

  final String identifier;
  final String arabicName;
  final String englishName;
  final int bitrateKbps;
  final int verifiedAyahCount;
}
