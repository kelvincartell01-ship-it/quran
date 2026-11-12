# Quran | قورئان

A Flutter application foundation for Android and iOS, built with Riverpod,
go_router, and Flutter's generated localization system.

## Requirements

- Flutter 3.47.2 or newer in the 3.x stable series
- Dart 3.13.2 or newer

The app starts in Sorani Kurdish and supports Sorani Kurdish (`ckb`), Arabic
(`ar`), and English (`en`). The Quran, Channels, and Settings destinations are
implemented as a state-preserving bottom-navigation shell. Language, theme
mode, and Quran text size preferences are stored locally.

The Quran tab includes an offline, searchable catalog of all 114 Surahs and a
local reading experience with Tanzil Uthmani text and the HQKSTD Sorani
translation. Source attribution and validation notes are in
[`assets/data/README.md`](assets/data/README.md).

Flutter does not currently ship Sorani translations for its framework-owned
Material and Cupertino controls. Those controls use Arabic framework strings
in Sorani mode. A localized notice in Settings discloses this fallback; the
app's own interface is Sorani and the layout remains right-to-left. Arabic and
English continue to use their normal Flutter framework localizations.

## Development

```shell
flutter pub get
flutter gen-l10n
dart format .
flutter analyze
flutter test
```

Generated localization code is written to `lib/l10n/app_localizations.dart`;
edit the ARB source files rather than the generated file.

## Unsigned iOS build

The `Unsigned iOS Release IPA` workflow runs on pushes to `main` and can also
be started from the GitHub Actions tab with **Run workflow**. It builds on
macOS without Apple signing credentials and uploads `Quran-unsigned.ipa` as the
`quran-unsigned-release-ipa` artifact. The IPA is unsigned and must be signed
and provisioned before installation on a device or App Store submission.

## Scope

Audio playback, downloads, streaming, notifications, reciter selection, and
Tafsir are not implemented in this phase.
