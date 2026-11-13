import SwiftUI
import WidgetKit

private let quranWidgetAppGroup = "group.com.example.quran"

private enum QuranWidgetDataKey {
  static let payload = "quran.widget.payload"
  static let schemaVersion = 1
  static let canonicalVerseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
    44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
    26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6,
    3, 5, 4, 5, 6,
  ]

  static func verseCount(for surahNumber: Int) -> Int? {
    guard (1...canonicalVerseCounts.count).contains(surahNumber) else {
      return nil
    }
    return canonicalVerseCounts[surahNumber - 1]
  }
}

private struct QuranWidgetPayload: Decodable {
  let schemaVersion: Int
  let surahNumber: Int
  let verseNumber: Int
  let arabicSurahName: String
  let surahTransliteration: String
  let arabicText: String
  let soraniTranslation: String

  var isValid: Bool {
    guard schemaVersion == QuranWidgetDataKey.schemaVersion,
      let verseCount = QuranWidgetDataKey.verseCount(for: surahNumber),
      (1...verseCount).contains(verseNumber)
    else {
      return false
    }
    return !arabicSurahName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !surahTransliteration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !soraniTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

struct QuranReadingEntry: TimelineEntry {
  let date: Date
  let surahNumber: Int?
  let verseNumber: Int?
  let arabicSurahName: String
  let surahTransliteration: String
  let arabicText: String
  let soraniTranslation: String

  var hasReading: Bool {
    guard let surahNumber, let verseNumber,
      let verseCount = QuranWidgetDataKey.verseCount(for: surahNumber)
    else {
      return false
    }
    return (1...verseCount).contains(verseNumber)
      && !arabicSurahName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !surahTransliteration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !soraniTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var widgetURL: URL? {
    guard hasReading, let surahNumber, let verseNumber else { return nil }
    return URL(
      string:
        "quran:///quran/surah/\(surahNumber)?ayah=\(verseNumber)&homeWidget")
  }
}

struct QuranReadingProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuranReadingEntry {
    emptyEntry()
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (QuranReadingEntry) -> Void
  ) {
    completion(loadEntry())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<QuranReadingEntry>) -> Void
  ) {
    completion(Timeline(entries: [loadEntry()], policy: .never))
  }

  private func emptyEntry() -> QuranReadingEntry {
    QuranReadingEntry(
      date: Date(),
      surahNumber: nil,
      verseNumber: nil,
      arabicSurahName: "",
      surahTransliteration: "",
      arabicText: "",
      soraniTranslation: "")
  }

  private func loadEntry() -> QuranReadingEntry {
    let defaults = UserDefaults(suiteName: quranWidgetAppGroup)
    guard let serializedPayload = defaults?.string(forKey: QuranWidgetDataKey.payload),
      let payload = try? JSONDecoder().decode(
        QuranWidgetPayload.self,
        from: Data(serializedPayload.utf8)),
      payload.isValid
    else {
      return emptyEntry()
    }

    return QuranReadingEntry(
      date: Date(),
      surahNumber: payload.surahNumber,
      verseNumber: payload.verseNumber,
      arabicSurahName: payload.arabicSurahName,
      surahTransliteration: payload.surahTransliteration,
      arabicText: payload.arabicText,
      soraniTranslation: payload.soraniTranslation)
  }
}

struct QuranReadingWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: QuranReadingEntry

  private let gold = Color(red: 0.91, green: 0.78, blue: 0.46)
  private let emerald = Color(red: 0.025, green: 0.22, blue: 0.17)
  private let deepEmerald = Color(red: 0.008, green: 0.12, blue: 0.09)

  var body: some View {
    Group {
      if #available(iOSApplicationExtension 17.0, *) {
        content.containerBackground(for: .widget) { background }
      } else {
        content.background(background)
      }
    }
    .widgetURL(entry.widgetURL)
  }

  @ViewBuilder
  private var content: some View {
    if family == .systemSmall {
      smallContent
    } else {
      mediumContent
    }
  }

  private var background: some View {
    ZStack {
      LinearGradient(
        colors: [emerald, deepEmerald],
        startPoint: .topLeading,
        endPoint: .bottomTrailing)
      Circle()
        .stroke(gold.opacity(0.1), lineWidth: 1)
        .frame(width: 190, height: 190)
        .offset(x: 125, y: -70)
    }
  }

  private var brand: some View {
    HStack(spacing: 7) {
      Image("QuranBranding")
        .resizable()
        .scaledToFit()
        .frame(width: 30, height: 30)
      Text("QURAN")
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .tracking(1.5)
        .foregroundStyle(gold)
    }
  }

  private var smallContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        brand
        Spacer(minLength: 4)
        Image(systemName: "bookmark.fill")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(gold.opacity(0.8))
      }

      Rectangle()
        .fill(gold.opacity(0.35))
        .frame(height: 1)

      Text("CONTINUE READING")
        .font(.system(size: 9, weight: .semibold, design: .rounded))
        .tracking(0.8)
        .foregroundStyle(gold.opacity(0.9))

      Spacer(minLength: 0)

      if entry.hasReading {
        VStack(alignment: .trailing, spacing: 3) {
          Text(entry.arabicSurahName)
            .font(.system(size: 17, weight: .bold, design: .serif))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)

          Text("Ayah \(entry.verseNumber!)")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(gold)
        }
      } else {
        Text("Open the Quran to begin")
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.white.opacity(0.8))
      }
    }
    .padding(14)
  }

  private var mediumContent: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack {
        brand
        Text("CONTINUE READING")
          .font(.system(size: 9, weight: .semibold, design: .rounded))
          .tracking(0.8)
          .foregroundStyle(gold.opacity(0.9))
        Spacer(minLength: 0)
        Image(systemName: "bookmark.fill")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(gold.opacity(0.8))
      }

      Rectangle()
        .fill(gold.opacity(0.35))
        .frame(height: 1)

      if entry.hasReading {
        Text(entry.arabicText)
          .font(.system(size: 23, weight: .regular, design: .serif))
          .lineLimit(4)
          .minimumScaleFactor(0.55)
          .foregroundStyle(.white)
          .multilineTextAlignment(.trailing)
          .frame(maxWidth: .infinity, alignment: .trailing)
          .environment(\.layoutDirection, .rightToLeft)

        Text(entry.soraniTranslation)
          .font(.system(size: 12, weight: .regular))
          .lineLimit(2)
          .minimumScaleFactor(0.75)
          .foregroundStyle(.white.opacity(0.82))
          .multilineTextAlignment(.trailing)
          .frame(maxWidth: .infinity, alignment: .trailing)
          .environment(\.layoutDirection, .rightToLeft)

        HStack {
          Spacer(minLength: 0)
          Text("\(entry.surahTransliteration) · \(entry.arabicSurahName)  ·  Ayah \(entry.verseNumber!)")
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(gold)
        }
      } else {
        Spacer(minLength: 0)
        Text("Open the Quran and choose an Ayah to continue.")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.white.opacity(0.82))
        Spacer(minLength: 0)
      }
    }
    .padding(13)
  }
}

@main
struct QuranReadingWidget: Widget {
  let kind = "QuranReadingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuranReadingProvider()) { entry in
      QuranReadingWidgetView(entry: entry)
    }
    .configurationDisplayName("Continue Reading")
    .description("Return to your most recent Ayah.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
