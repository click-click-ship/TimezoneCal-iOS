import Foundation
import SwiftUI

/// Represents the local time-of-day / work status for a city at a given timestamp.
public enum DayPhase: String, Codable, CaseIterable, Sendable {
    case working = "Working Hours"     // 09:00 – 17:59
    case morning = "Morning"           // 06:00 – 08:59
    case evening = "Evening"           // 18:00 – 21:59
    case sleeping = "Sleeping"         // 22:00 – 05:59

    /// SF Symbol icon matching Apple Calendar / Weather semantics
    public var symbolName: String {
        switch self {
        case .working:
            return "sun.max.fill"
        case .morning:
            return "sunrise.fill"
        case .evening:
            return "sunset.fill"
        case .sleeping:
            return "moon.stars.fill"
        }
    }

    /// Compact emoji for Lock Screen inline widgets and text snippets
    public var emoji: String {
        switch self {
        case .working:  return "☀️"
        case .morning:  return "🌅"
        case .evening:  return "🌆"
        case .sleeping: return "🌙"
        }
    }

    /// Whether this hour is reasonable for scheduling a meeting (08:00 – 18:59)
    public var isAwakeWorkFriendly: Bool {
        switch self {
        case .working:
            return true
        case .morning, .evening, .sleeping:
            return false
        }
    }

    /// Determine phase from a 24-hour integer (0...23)
    public static func from(hour: Int) -> DayPhase {
        let normalized = ((hour % 24) + 24) % 24
        switch normalized {
        case 9...17:
            return .working
        case 6...8:
            return .morning
        case 18...21:
            return .evening
        default:
            return .sleeping
        }
    }
}

/// Represents a city and its associated IANA TimeZone identifier.
public struct CityTimezone: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var cityName: String
    public var countryOrRegion: String
    public var countryCode: String
    public var timeZoneIdentifier: String
    public var shortCode: String

    public init(
        id: String? = nil,
        cityName: String,
        countryOrRegion: String,
        countryCode: String,
        timeZoneIdentifier: String,
        shortCode: String? = nil
    ) {
        self.id = id ?? "\(cityName.lowercased().replacingOccurrences(of: " ", with: "_"))_\(timeZoneIdentifier)"
        self.cityName = cityName
        self.countryOrRegion = countryOrRegion
        self.countryCode = countryCode
        self.timeZoneIdentifier = timeZoneIdentifier
        if let shortCode = shortCode {
            self.shortCode = shortCode.uppercased()
        } else {
            let letters = cityName.uppercased().filter { $0.isLetter }
            self.shortCode = String(letters.prefix(3))
        }
    }

    /// Resolved Foundation `TimeZone` (falls back to `.current` if identifier is invalid)
    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    /// Flag emoji computed from the 2-letter ISO country code
    public var flagEmoji: String {
        let base: UInt32 = 127397
        var s = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                s.unicodeScalars.append(flagScalar)
            }
        }
        return s.isEmpty ? "🌐" : s
    }

    // MARK: - Time & Calendar Calculations

    /// Returns the local hour (0...23) and minute (0...59) in this city at the given `Date`.
    public func localComponents(at date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .weekday, .hour, .minute, .second], from: date)
    }

    /// Returns the `DayPhase` in this city at the given `Date`.
    public func dayPhase(at date: Date) -> DayPhase {
        let hour = localComponents(at: date).hour ?? 12
        return DayPhase.from(hour: hour)
    }

    /// Returns whether this city is within "Golden Overlap" friendly meeting hours (8:00 AM – 6:00 PM) at `date`.
    public func isGoldenMeetingHour(at date: Date) -> Bool {
        let hour = localComponents(at: date).hour ?? 12
        return (8...17).contains(hour)
    }

    /// Formatted time string (e.g. "9:30 AM" or "09:30") in this city's timezone.
    public func formattedTime(at date: Date, use24Hour: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    /// Formatted hour label for compact timeline cells (e.g. "9a", "12p", "14").
    public func compactHourLabel(forHour hour: Int, use24Hour: Bool = false) -> String {
        let h = ((hour % 24) + 24) % 24
        if use24Hour {
            return String(format: "%02d", h)
        }
        if h == 0 { return "12a" }
        if h == 12 { return "12p" }
        return h < 12 ? "\(h)a" : "\(h - 12)p"
    }

    /// Formatted date label (e.g. "Thu, Nov 19") in this city's timezone.
    public func formattedShortDate(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    /// Timezone abbreviation at `date` (e.g. "PST", "EDT", "GMT", "JST").
    public func abbreviation(at date: Date) -> String {
        timeZone.abbreviation(for: date) ?? shortCode
    }

    /// Offset in hours (supports half/quarter hour zones like India +5.5 or Nepal +5.75) relative to a reference city at `date`.
    public func offsetHours(relativeTo reference: CityTimezone, at date: Date) -> Double {
        let mySeconds = timeZone.secondsFromGMT(for: date)
        let refSeconds = reference.timeZone.secondsFromGMT(for: date)
        return Double(mySeconds - refSeconds) / 3600.0
    }

    /// Human-readable relative offset string (e.g., "HOME", "SAME TIME", "+3 HRS", "-5.5 HRS").
    public func formattedOffsetBadge(relativeTo reference: CityTimezone, at date: Date, isReference: Bool = false) -> String {
        if isReference {
            return "REFERENCE"
        }
        let diff = offsetHours(relativeTo: reference, at: date)
        if abs(diff) < 0.01 {
            return "SAME TIME"
        }
        let sign = diff > 0 ? "+" : ""
        if abs(diff.truncatingRemainder(dividingBy: 1)) < 0.01 {
            let intHours = Int(diff.rounded())
            return "\(sign)\(intHours) \(abs(intHours) == 1 ? "HR" : "HRS")"
        } else {
            return String(format: "%@%.1f HRS", sign, diff)
        }
    }

    /// Relative calendar day shift compared to the reference city ("Yesterday", "Today", "Tomorrow").
    public func relativeDayLabel(relativeTo reference: CityTimezone, at date: Date) -> String {
        let myComp = localComponents(at: date)
        let refComp = reference.localComponents(at: date)

        guard let myY = myComp.year, let myM = myComp.month, let myD = myComp.day,
              let refY = refComp.year, let refM = refComp.month, let refD = refComp.day else {
            return "Today"
        }

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0)!
        let myNoon = utcCal.date(from: DateComponents(year: myY, month: myM, day: myD, hour: 12)) ?? date
        let refNoon = utcCal.date(from: DateComponents(year: refY, month: refM, day: refD, hour: 12)) ?? date

        let dayDiff = utcCal.dateComponents([.day], from: refNoon, to: myNoon).day ?? 0
        switch dayDiff {
        case ..<0: return "Yesterday"
        case 0:    return "Today"
        default:   return "Tomorrow"
        }
    }

    // MARK: - Smart Daylight Saving Time (DST) Transition Detection

    /// Detects if the offset between `self` and `reference` on `targetDate` differs from today's offset (`now`).
    /// Returns a human-readable warning message if a DST mismatch exists, or `nil` if unchanged.
    public func dstTransitionWarning(relativeTo reference: CityTimezone, on targetDate: Date, now: Date = .now) -> String? {
        let currentOffset = offsetHours(relativeTo: reference, at: now)
        let targetOffset = offsetHours(relativeTo: reference, at: targetDate)
        let delta = targetOffset - currentOffset

        guard abs(delta) >= 0.25 else { return nil }

        let targetBadge = formattedOffsetBadge(relativeTo: reference, at: targetDate)
        let currentBadge = formattedOffsetBadge(relativeTo: reference, at: now)
        return "\(cityName) is \(targetBadge) on this date (currently \(currentBadge)) due to Daylight Saving Time."
    }
}
