import 'dart:convert';

import 'package:flutter/services.dart';

import 'quran_reciter.dart';

class AssetQuranReciterDataSource {
  const AssetQuranReciterDataSource();

  static const _assetPath = 'assets/data/audio_reciters.json';

  Future<List<QuranReciter>> loadReciters() async {
    final decoded = jsonDecode(await rootBundle.loadString(_assetPath));
    if (decoded is! Map<String, dynamic> || decoded['reciters'] is! List) {
      throw const FormatException('The local reciter catalog is malformed.');
    }

    final reciters = (decoded['reciters'] as List)
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('A reciter record is malformed.');
          }
          return QuranReciter.fromJson(item);
        })
        .toList(growable: false);
    final identifiers = reciters.map((reciter) => reciter.identifier).toSet();
    if (reciters.length < 11 || identifiers.length != reciters.length) {
      throw const FormatException(
        'The reciter catalog must contain at least 11 unique records.',
      );
    }
    return List.unmodifiable(reciters);
  }
}
