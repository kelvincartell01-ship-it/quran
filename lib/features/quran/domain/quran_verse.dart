import 'package:flutter/foundation.dart';

@immutable
class VerseReference {
  const VerseReference({required this.surahNumber, required this.verseNumber});

  final int surahNumber;
  final int verseNumber;

  @override
  bool operator ==(Object other) =>
      other is VerseReference &&
      other.surahNumber == surahNumber &&
      other.verseNumber == verseNumber;

  @override
  int get hashCode => Object.hash(surahNumber, verseNumber);
}

@immutable
class QuranVerse {
  const QuranVerse({
    required this.surahNumber,
    required this.verseNumber,
    required this.globalVerseNumber,
    required this.arabicText,
    this.surahOpeningBismillah,
    required this.soraniTranslation,
  });

  final int surahNumber;
  final int verseNumber;
  final int globalVerseNumber;
  final String arabicText;
  final String? surahOpeningBismillah;
  final String soraniTranslation;
}
