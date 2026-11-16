import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

/// User appearance override preference (supports Auto Day/Night system mode or manual lock).
public enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case auto = "Auto (System)"
    case light = "Day (Light)"
    case dark = "Night (Dark)"

    public var colorScheme: ColorScheme? {
        switch self {
        case .auto:  return nil
        case .light: return .light
        case .dark:  return .dark
        }
    }

    public var symbolName: String {
        switch self {
        case .auto:  return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark:  return "moon.stars.fill"
        }
    }
}

/// Represents a detected "Golden Hours" overlap window in the reference city's 24-hour day.
public struct GoldenOverlapWindow: Equatable, Sendable {
    public let startHourInReference: Int
    public let endHourInReference: Int
    public let matchingCityCount: Int
    public let totalCityCount: Int

    public var isFullTeamOverlap: Bool {
        matchingCityCount == totalCityCount
    }
}

/// Central Observable data store shared between the main SwiftUI app and WidgetKit extensions via App Group.
@MainActor
public final class TimezoneStore: ObservableObject {

    public static let appGroupIdentifier = "group.com.timezonecal.shared"
    public static let shared = TimezoneStore()

    // MARK: - Published State

    /// User's primary home timezone (always anchored at top of converter).
    @Published public var homeCity: CityTimezone {
        didSet { saveAndReloadWidgets() }
    }

    /// Which city is currently acting as the active "Reference" clock when dialing a time.
    /// Defaults to `homeCity.id`, but tapping any city card switches reference to that city!
    @Published public var activeReferenceCityID: String

    /// Preset city groups ("Work Team", "Family", "Travel", etc.).
    @Published public var groups: [CityGroup] {
        didSet { saveAndReloadWidgets() }
    }

    /// Currently selected preset group ID.
    @Published public var selectedGroupID: String {
        didSet { saveAndReloadWidgets() }
    }

    /// Up to 3 city IDs pinned specifically for Home Screen & Lock Screen widgets.
    @Published public var widgetPinnedCityIDs: [String] {
        didSet { saveAndReloadWidgets() }
    }

    /// Currently selected timestamp on the calendar & time scrubber.
    @Published public var selectedDate: Date = .now

    /// Whether the user has scrubbed away from live `.now` time.
    @Published public var isScrubbingCustomTime: Bool = false

    /// 12-hour vs 24-hour formatting preference.
    @Published public var use24HourFormat: Bool {
        didSet { saveAndReloadWidgets() }
    }

    /// Auto Day/Night vs Manual appearance preference.
    @Published public var appearanceMode: AppearanceMode {
        didSet { saveAndReloadWidgets() }
    }

    /// Hour offset applied by interactive Home Screen widget buttons (`-1h`, `Now`, `+1h`).
    @Published public var widgetHourOffset: Int {
        didSet { saveAndReloadWidgets() }
    }

    private let defaults: UserDefaults
    private var liveClockTimer: Timer?

    // MARK: - Persistence Keys

    private enum Keys {
        static let homeCity = "tzcal.homeCity"
        static let groups = "tzcal.groups"
        static let selectedGroupID = "tzcal.selectedGroupID"
        static let widgetPinnedCityIDs = "tzcal.widgetPinnedCityIDs"
        static let use24HourFormat = "tzcal.use24HourFormat"
        static let appearanceMode = "tzcal.appearanceMode"
        static let widgetHourOffset = "tzcal.widgetHourOffset"
    }

    // MARK: - Initialization

    public init() {
        let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) ?? .standard
        self.defaults = sharedDefaults

        let decoder = JSONDecoder()

        if let data = sharedDefaults.data(forKey: Keys.homeCity),
           let decodedHome = try? decoder.decode(CityTimezone.self, from: data) {
            self.homeCity = decodedHome
        } else {
            self.homeCity = CityCatalog.detectDeviceHomeCity()
        }

        let loadedGroups: [CityGroup]
        if let data = sharedDefaults.data(forKey: Keys.groups),
           let decodedGroups = try? decoder.decode([CityGroup].self, from: data),
           !decodedGroups.isEmpty {
            loadedGroups = decodedGroups
        } else {
            loadedGroups = CityGroup.defaultGroups
        }
        self.groups = loadedGroups

        let savedGroupID = sharedDefaults.string(forKey: Keys.selectedGroupID)
        if let savedGroupID, loadedGroups.contains(where: { $0.id == savedGroupID }) {
            self.selectedGroupID = savedGroupID
        } else {
            self.selectedGroupID = loadedGroups.first?.id ?? "group_work"
        }

        if let savedPins = sharedDefaults.stringArray(forKey: Keys.widgetPinnedCityIDs), !savedPins.isEmpty {
            self.widgetPinnedCityIDs = savedPins
        } else {
            let firstThree = loadedGroups.first?.cities.prefix(3).map(\.id) ?? [
                CityCatalog.newYork.id,
                CityCatalog.london.id,
                CityCatalog.tokyo.id
            ]
            self.widgetPinnedCityIDs = Array(firstThree)
        }

        self.use24HourFormat = sharedDefaults.bool(forKey: Keys.use24HourFormat)

        if let rawAppearance = sharedDefaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: rawAppearance) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .auto
        }

        self.widgetHourOffset = sharedDefaults.integer(forKey: Keys.widgetHourOffset)
        self.activeReferenceCityID = self.homeCity.id

        startLiveClockIfNeeded()
    }

    // MARK: - Computed Helpers

    /// Currently active preset group.
    public var activeGroup: CityGroup {
        groups.first(where: { $0.id == selectedGroupID }) ?? groups.first ?? CityGroup.defaultGroups[0]
    }

    /// Cities in the active group.
    public var activeCities: [CityTimezone] {
        activeGroup.cities
    }

    /// All cities being compared (Home City + Active Group cities).
    public var allComparedCities: [CityTimezone] {
        [homeCity] + activeCities.filter { $0.id != homeCity.id }
    }

    /// The currently selected Reference City (either `homeCity` or any tapped city in the list).
    public var referenceCity: CityTimezone {
        if activeReferenceCityID == homeCity.id {
            return homeCity
        }
        return activeCities.first(where: { $0.id == activeReferenceCityID }) ?? homeCity
    }

    /// The 3 cities configured for WidgetKit display.
    public var widgetCities: [CityTimezone] {
        let allKnown = Dictionary(
            uniqueKeysWithValues: (groups.flatMap(\.cities) + CityCatalog.curatedCities).map { ($0.id, $0) }
        )
        let resolved = widgetPinnedCityIDs.compactMap { allKnown[$0] }
        if !resolved.isEmpty {
            return Array(resolved.prefix(3))
        }
        return Array(activeCities.prefix(3))
    }

    // MARK: - Reference & Time Scrubbing Actions

    /// Tap any city card to make it the active Reference timezone for dialing times.
    public func setReferenceCity(_ city: CityTimezone) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
            activeReferenceCityID = city.id
        }
    }

    /// Reset `selectedDate` to live `.now` and return reference to Home City.
    public func resetToNow() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            selectedDate = .now
            isScrubbingCustomTime = false
            activeReferenceCityID = homeCity.id
            widgetHourOffset = 0
        }
    }

    /// Set the time of day (hour & minute) in the currently active `referenceCity` while preserving its calendar date.
    public func setTimeInReferenceCity(hour: Int, minute: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = referenceCity.timeZone

        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate)
        comps.hour = max(0, min(23, hour))
        comps.minute = max(0, min(59, minute))
        comps.second = 0

        if let updated = cal.date(from: comps) {
            selectedDate = updated
            isScrubbingCustomTime = true
        }
    }

    /// Shift `selectedDate` by a number of minutes (e.g. +15, -15, +60).
    public func shiftSelectedTime(byMinutes minutes: Int) {
        if let shifted = Calendar.current.date(byAdding: .minute, value: minutes, to: selectedDate) {
            selectedDate = shifted
            isScrubbingCustomTime = true
        }
    }

    /// Change the calendar date (year, month, day) in the active `referenceCity` while keeping the current time-of-day.
    public func selectCalendarDay(_ newDate: Date) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = referenceCity.timeZone

        let dayComps = cal.dateComponents([.year, .month, .day], from: newDate)
        let timeComps = cal.dateComponents([.hour, .minute], from: selectedDate)

        var merged = DateComponents()
        merged.year = dayComps.year
        merged.month = dayComps.month
        merged.day = dayComps.day
        merged.hour = timeComps.hour
        merged.minute = timeComps.minute
        merged.second = 0

        if let updated = cal.date(from: merged) {
            selectedDate = updated
            isScrubbingCustomTime = !cal.isDateInToday(updated)
        }
    }

    // MARK: - City & Group Editing Actions

    public func addCity(_ city: CityTimezone) {
        guard let idx = groups.firstIndex(where: { $0.id == selectedGroupID }) else { return }
        guard !groups[idx].cities.contains(where: { $0.id == city.id }) else { return }
        groups[idx].cities.append(city)
    }

    public func removeCities(at offsets: IndexSet) {
        guard let idx = groups.firstIndex(where: { $0.id == selectedGroupID }) else { return }
        groups[idx].cities.remove(atOffsets: offsets)
        if !allComparedCities.contains(where: { $0.id == activeReferenceCityID }) {
            activeReferenceCityID = homeCity.id
        }
    }

    public func removeCity(_ city: CityTimezone) {
        guard let idx = groups.firstIndex(where: { $0.id == selectedGroupID }) else { return }
        groups[idx].cities.removeAll { $0.id == city.id }
        if activeReferenceCityID == city.id {
            activeReferenceCityID = homeCity.id
        }
    }

    public func moveCities(from source: IndexSet, to destination: Int) {
        guard let idx = groups.firstIndex(where: { $0.id == selectedGroupID }) else { return }
        groups[idx].cities.move(fromOffsets: source, toOffset: destination)
    }

    public func addGroup(name: String, iconName: String = "folder.fill") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newGroup = CityGroup(
            name: trimmed,
            iconName: iconName,
            cities: [CityCatalog.newYork, CityCatalog.london]
        )
        groups.append(newGroup)
        selectedGroupID = newGroup.id
    }

    public func deleteGroup(_ group: CityGroup) {
        guard groups.count > 1 else { return }
        groups.removeAll { $0.id == group.id }
        if selectedGroupID == group.id {
            selectedGroupID = groups.first?.id ?? ""
        }
    }

    public func toggleWidgetPin(for city: CityTimezone) {
        if let existingIdx = widgetPinnedCityIDs.firstIndex(of: city.id) {
            if widgetPinnedCityIDs.count > 1 {
                widgetPinnedCityIDs.remove(at: existingIdx)
            }
        } else {
            if widgetPinnedCityIDs.count >= 3 {
                widgetPinnedCityIDs.removeFirst()
            }
            widgetPinnedCityIDs.append(city.id)
        }
    }

    // MARK: - "Golden Hours" Overlap Detector & DST Warnings

    /// Returns a 24-element array (for hours 0...23 in `referenceCity`) indicating how many cities are in friendly meeting hours (8am–6pm).
    public func hourlyOverlapCountsInReferenceDay() -> [Int] {
        let compared = allComparedCities
        guard !compared.isEmpty else { return Array(repeating: 0, count: 24) }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = referenceCity.timeZone
        let baseComps = cal.dateComponents([.year, .month, .day], from: selectedDate)

        return (0..<24).map { refHour in
            var c = baseComps
            c.hour = refHour
            c.minute = 0
            guard let probeDate = cal.date(from: c) else { return 0 }
            return compared.filter { $0.isGoldenMeetingHour(at: probeDate) }.count
        }
    }

    /// Finds the best contiguous window of overlapping working hours across `allComparedCities`.
    public var bestGoldenOverlapWindow: GoldenOverlapWindow? {
        let compared = allComparedCities
        guard compared.count >= 2 else { return nil }
        let counts = hourlyOverlapCountsInReferenceDay()
        guard let maxCount = counts.max(), maxCount >= 2 else { return nil }

        // Find the longest contiguous run of `maxCount`
        var bestStart = 9
        var bestLength = 0
        var currentStart: Int? = nil
        var currentLength = 0

        for hour in 0..<24 {
            if counts[hour] == maxCount {
                if currentStart == nil {
                    currentStart = hour
                    currentLength = 1
                } else {
                    currentLength += 1
                }
                if currentLength > bestLength {
                    bestLength = currentLength
                    bestStart = currentStart ?? hour
                }
            } else {
                currentStart = nil
                currentLength = 0
            }
        }

        let endHour = min(23, bestStart + max(1, bestLength) - 1)
        return GoldenOverlapWindow(
            startHourInReference: bestStart,
            endHourInReference: endHour,
            matchingCityCount: maxCount,
            totalCityCount: compared.count
        )
    }

    /// Returns all active DST transition warnings for `selectedDate` compared to today.
    public var activeDSTWarnings: [String] {
        allComparedCities
            .filter { $0.id != referenceCity.id }
            .compactMap { $0.dstTransitionWarning(relativeTo: referenceCity, on: selectedDate) }
    }

    // MARK: - Persistence & Live Clock

    private func startLiveClockIfNeeded() {
        liveClockTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isScrubbingCustomTime else { return }
                self.selectedDate = .now
            }
        }
    }

    public func saveAndReloadWidgets() {
        let encoder = JSONEncoder()
        if let homeData = try? encoder.encode(homeCity) {
            defaults.set(homeData, forKey: Keys.homeCity)
        }
        if let groupsData = try? encoder.encode(groups) {
            defaults.set(groupsData, forKey: Keys.groups)
        }
        defaults.set(selectedGroupID, forKey: Keys.selectedGroupID)
        defaults.set(widgetPinnedCityIDs, forKey: Keys.widgetPinnedCityIDs)
        defaults.set(use24HourFormat, forKey: Keys.use24HourFormat)
        defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
        defaults.set(widgetHourOffset, forKey: Keys.widgetHourOffset)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
