import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/surah.dart';

abstract interface class SurahMetadataDataSource {
  Future<List<Surah>> loadSurahs();
}

class AssetSurahMetadataDataSource implements SurahMetadataDataSource {
  const AssetSurahMetadataDataSource({this._bundle});

  static const assetPath = 'assets/data/surahs.json';
  static const expectedSurahCount = 114;
  static const expectedVerseCount = 6236;

  final AssetBundle? _bundle;

  @override
  Future<List<Surah>> loadSurahs() async {
    final contents = await (_bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported Surah metadata format.');
    }

    final rawSurahs = decoded['surahs'];
    if (rawSurahs is! List<dynamic>) {
      throw const FormatException('Surah metadata must contain a list.');
    }

    final surahs = rawSurahs
        .map((record) {
          if (record is! Map<String, dynamic>) {
            throw const FormatException('A Surah metadata record is invalid.');
          }
          return Surah.fromJson(record);
        })
        .toList(growable: false);

    _validate(surahs);
    return List.unmodifiable(surahs);
  }

  void _validate(List<Surah> surahs) {
    if (surahs.length != expectedSurahCount) {
      throw FormatException(
        'Expected $expectedSurahCount Surahs; found ${surahs.length}.',
      );
    }

    final numbers = surahs.map((surah) => surah.number).toSet();
    if (numbers.length != expectedSurahCount) {
      throw const FormatException('Surah numbers must be unique.');
    }

    for (var index = 0; index < surahs.length; index++) {
      final surah = surahs[index];
      if (surah.number != index + 1) {
        throw const FormatException(
          'Surahs must be in canonical numbered order.',
        );
      }
      if (surah.verseCount <= 0 || surah.revelationOrder <= 0) {
        throw const FormatException(
          'Verse counts and revelation orders must be positive.',
        );
      }
    }

    final totalVerses = surahs.fold<int>(
      0,
      (total, surah) => total + surah.verseCount,
    );
    if (totalVerses != expectedVerseCount) {
      throw FormatException(
        'Expected $expectedVerseCount verses; found $totalVerses.',
      );
    }

    if (surahs.first.arabicName != 'الفاتحة' ||
        surahs.last.arabicName != 'الناس') {
      throw const FormatException(
        'The Surah list must start with Al-Fatihah and end with An-Nas.',
      );
    }
  }
}
