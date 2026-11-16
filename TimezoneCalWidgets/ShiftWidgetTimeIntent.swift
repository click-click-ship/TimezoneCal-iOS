import AppIntents
import Foundation
import WidgetKit

/// iOS 17+ interactive Widget AppIntent to scrub the widget timeline forward or backward by `deltaHours`.
public struct ShiftWidgetTimeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Shift Widget Preview Time"
    public static var description = IntentDescription("Shifts the displayed timezone comparison forward or backward by 1 hour.")

    @Parameter(title: "Hours Delta")
    public var deltaHours: Int

    public init() {
        self.deltaHours = 1
    }

    public init(deltaHours: Int) {
        self.deltaHours = deltaHours
    }

    public func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.timezonecal.shared") ?? .standard
        let current = defaults.integer(forKey: "tzcal.widgetHourOffset")
        defaults.set(current + deltaHours, forKey: "tzcal.widgetHourOffset")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// iOS 17+ interactive Widget AppIntent to reset the widget timeline offset back to live `.now`.
public struct ResetWidgetTimeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Reset Widget to Live Time"

    public init() {}

    public func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.timezonecal.shared") ?? .standard
        defaults.set(0, forKey: "tzcal.widgetHourOffset")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Shared WidgetKit TimelineEntry containing the user's Home City, 3 Pinned Cities, and active hour offset.
public struct TimezoneWidgetEntry: TimelineEntry {
    public let date: Date
    public let homeCity: CityTimezone
    public let pinnedCities: [CityTimezone]
    public let use24HourFormat: Bool
    public let hourOffset: Int

    public var effectiveDate: Date {
        Calendar.current.date(byAdding: .hour, value: hourOffset, to: date) ?? date
    }

    public static var sample: TimezoneWidgetEntry {
        TimezoneWidgetEntry(
            date: .now,
            homeCity: CityCatalog.sanFrancisco,
            pinnedCities: [
                CityCatalog.newYork,
                CityCatalog.london,
                CityCatalog.tokyo
            ],
            use24HourFormat: false,
            hourOffset: 0
        )
    }
}

/// Shared TimelineProvider reading configuration from the App Group `group.com.timezonecal.shared`.
public struct TimezoneWidgetProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> TimezoneWidgetEntry {
        .sample
    }

    public func getSnapshot(in context: Context, completion: @escaping (TimezoneWidgetEntry) -> Void) {
        completion(loadEntry(for: .now))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<TimezoneWidgetEntry>) -> Void) {
        let now = Date.now
        var entries: [TimezoneWidgetEntry] = []

        // Generate 15-minute timeline entries for the next 4 hours
        for quarter in 0..<16 {
            if let entryDate = Calendar.current.date(byAdding: .minute, value: quarter * 15, to: now) {
                entries.append(loadEntry(for: entryDate))
            }
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func loadEntry(for date: Date) -> TimezoneWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.timezonecal.shared") ?? .standard
        let decoder = JSONDecoder()

        let home: CityTimezone
        if let homeData = defaults.data(forKey: "tzcal.homeCity"),
           let decoded = try? decoder.decode(CityTimezone.self, from: homeData) {
            home = decoded
        } else {
            home = CityCatalog.detectDeviceHomeCity()
        }

        var allCities: [CityTimezone] = CityCatalog.curatedCities
        if let groupData = defaults.data(forKey: "tzcal.groups"),
           let groups = try? decoder.decode([CityGroup].self, from: groupData) {
            allCities = groups.flatMap(\.cities) + allCities
        }

        let lookup = Dictionary(uniqueKeysWithValues: allCities.map { ($0.id, $0) })
        let pinIDs = defaults.stringArray(forKey: "tzcal.widgetPinnedCityIDs") ?? [
            CityCatalog.newYork.id,
            CityCatalog.london.id,
            CityCatalog.tokyo.id
        ]

        let resolvedPins = pinIDs.compactMap { lookup[$0] }
        let finalPins = resolvedPins.isEmpty
            ? [CityCatalog.newYork, CityCatalog.london, CityCatalog.tokyo]
            : Array(resolvedPins.prefix(3))

        let use24 = defaults.bool(forKey: "tzcal.use24HourFormat")
        let offset = defaults.integer(forKey: "tzcal.widgetHourOffset")

        return TimezoneWidgetEntry(
            date: date,
            homeCity: home,
            pinnedCities: finalPins,
            use24HourFormat: use24,
            hourOffset: offset
        )
    }
}
