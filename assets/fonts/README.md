# Quran fonts

The reader bundles Amiri Quran, release 1.003, by the Amiri Project.

- Source: https://github.com/aliftype/amiri/releases/tag/1.003
- License: SIL Open Font License 1.1; the full license is in `OFL.txt`.
- The font is registered as `AmiriQuran` in `pubspec.yaml` and is not
  represented as an official Uthmani Hafs edition.
- Its cmap covers all 70 distinct Unicode characters in the bundled Tanzil
  text; OpenType GSUB and GPOS tables are present.
- Flutter widget tests render marked Arabic and long verses with the local
  font. Device-level visual review remains pending.

The font is used only for rendering and does not alter Quran text.
