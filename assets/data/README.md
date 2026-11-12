# Quran text, translation, and font attribution

## Surah metadata

- Source: Tanzil Quran Metadata, Version 1.0:
  https://tanzil.net/res/text/metadata/quran-data.xml
- The source states its license as CC BY. The Phase 2 conversion retains the
  Arabic names, transliterations, verse counts, and revelation order.
- Verse counts and Makki/Madani classifications were cross-checked against
  Quran.com API v4 chapters: https://api.quran.com/api/v4/chapters?language=en
- All 114 records matched the independent verse-count and revelation-place
  checks.

## Tanzil Quran Text

- Project: Tanzil Quran Text, Version 1.1 (February 2021).
- Source and download: https://tanzil.net/download
- Text license and terms: https://tanzil.net/docs/Text_License
- Copyright notice required by the bundled source: `Copyright (C) 2007-2026 Tanzil Project`
- The bundled XML copyright block was preserved; the generated runtime asset
  repeats this notice with the source's CC BY 3.0 license.
- License: CC BY 3.0. Verbatim text may be redistributed in applications when Tanzil is clearly credited and linked. Changing the Quran text is not allowed.
- Source: the Tanzil Uthmani XML export, with pause marks, sajdah and
  rub-el-hizb signs, and tatweel below superscript alefs.
- `source/tanzil-uthmani-v1.1.xml` is the original UTF-8 download, copied
  without editing. Its copyright block is retained.
- Download SHA-256:
  `af9311c521b5dadab01ea1ef259c281ffa83cf224bad24ee89469ce1c3c72916`.
- `quran-uthmani.json` is the generated runtime asset. Each verse's `aya@text`
  is preserved verbatim; an optional Surah-opening formula is stored separately
  from verse 1 when provided by the XML `aya@bismillah` attribute. This avoids
  pairing that formula with a verse's numbered Sorani translation. Al-Fatihah's
  opening formula remains part of its actual first verse, and At-Tawbah has no
  separate opening formula.

## Sorani translation

- Dataset: Holy Quran Kurdish Sorani Translation Dataset (HQKSTD), Version 1.
- Contributors: Shakhawan Hares Wady, Mhamad Bamoki, and Soran Badawi.
- Dataset: https://data.mendeley.com/datasets/byyjd7kmvd/1
- DOI: https://doi.org/10.17632/byyjd7kmvd.1
- Source file: `Cleaned_Holy_Quran_Kurdish_Dataset.xlsx`.
- Source workbook SHA-256: `1e5b351bd0c1493ac181d9853c72941a6e1c0c6b3839a658dce1ad33a9a04e23`.
- License: Creative Commons Attribution 4.0 International (CC BY 4.0): https://creativecommons.org/licenses/by/4.0/
- The `CleanedKurdishTranslation` column was converted to `sorani-translation.json`. Translation strings are not machine-translated, paraphrased, or trimmed. Records retain Surah number, verse number, and global verse number.
- The app labels this content **Verse meaning** (`واتای ئایەت`); it is a translation dataset, not a Tafsir edition.

## Import and validation

The reproducible importer uses only Python's standard library. Download the
Tanzil Uthmani XML export and the cleaned HQKSTD workbook, then run:

```shell
python tool/import_quran_data.py --tanzil <path-to-tanzil-export.xml> --translation-xlsx <path-to-cleaned-workbook.xlsx>
```

The importer checks both sources against the Phase 2 Surah metadata and
rejects missing, duplicate, reordered, or misaligned records. It copies the
Tanzil XML byte-for-byte into `source/`, generates the structured Quran JSON,
and writes the translation JSON in UTF-8. Only the JSON is bundled as a
Flutter runtime asset.

Validated data contains 114 Surahs and 6,236 verses, with every Surah/verse
key aligned and every source translation non-empty.

## Quran font

- Font: Amiri Quran, Amiri Project, release 1.003.
- Source: https://github.com/aliftype/amiri/releases/tag/1.003
- License: SIL Open Font License 1.1; the original license is bundled at
  `assets/fonts/OFL.txt`.
- OFL 1.1 permits the font to be embedded and redistributed with software
  when the copyright notice and license accompany it; both are included here.
- The font is not represented as an official Uthmani Hafs edition. Its Unicode
  character map was checked against every character in the bundled Tanzil
  text; all 70 distinct text characters have glyphs. OpenType GSUB and GPOS
  tables are present. Flutter widget tests render the marked Arabic and long
  verses with the registered local font. Device-level visual review remains
  pending. The font is used for rendering only and does not alter source text.

The same source and license information is available from Settings in the app.
