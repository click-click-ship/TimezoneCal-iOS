import Foundation
#if canImport(EventKit)
import EventKit
#endif

/// Generates formatted multi-timezone meeting snippets and creates native Apple Calendar (`EventKit`) events.
public enum CalendarExportService {

    /// Builds a clean, human-friendly multi-timezone availability / invite block ready to paste into Slack, iMessage, or Email.
    public static func buildShareSnippet(
        title: String = "Proposed Meeting",
        startDate: Date,
        durationMinutes: Int = 60,
        cities: [CityTimezone],
        referenceCity: CityTimezone,
        use24Hour: Bool
    ) -> String {
        let endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate
        let refDateLabel = referenceCity.formattedShortDate(at: startDate)

        var lines: [String] = []
        lines.append("📅 \(title) — \(refDateLabel)")
        lines.append(String(repeating: "─", count: 32))

        for city in cities {
            let startStr = city.formattedTime(at: startDate, use24Hour: use24Hour)
            let endStr = city.formattedTime(at: endDate, use24Hour: use24Hour)
            let abbr = city.abbreviation(at: startDate)
            let dayShift = city.relativeDayLabel(relativeTo: referenceCity, at: startDate)
            let daySuffix = (dayShift == "Today") ? "" : " (\(dayShift))"
            let phaseEmoji = city.dayPhase(at: startDate).emoji

            lines.append("\(phaseEmoji) \(city.flagEmoji) \(city.cityName) (\(abbr)): \(startStr) – \(endStr)\(daySuffix)")
        }

        lines.append(String(repeating: "─", count: 32))
        lines.append("Shared via TimezoneCal")
        return lines.joined(separator: "\n")
    }

    /// Creates an event directly in the user's native iOS Apple Calendar (`EventKit`) with all converted city times in the notes.
    public static func addEventToAppleCalendar(
        title: String,
        startDate: Date,
        durationMinutes: Int = 60,
        cities: [CityTimezone],
        referenceCity: CityTimezone,
        use24Hour: Bool
    ) async throws -> String {
        let notes = buildShareSnippet(
            title: title,
            startDate: startDate,
            durationMinutes: durationMinutes,
            cities: cities,
            referenceCity: referenceCity,
            use24Hour: use24Hour
        )

        #if canImport(EventKit)
        let eventStore = EKEventStore()
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = try await eventStore.requestWriteOnlyAccessToEvents()
        } else {
            granted = try await eventStore.requestAccess(to: .event)
        }

        guard granted else {
            throw NSError(
                domain: "TimezoneCal.CalendarExport",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Calendar permission was not granted. Please enable Calendar access in Settings."]
            )
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title.isEmpty ? "Global Team Sync" : title
        event.startDate = startDate
        event.endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate.addingTimeInterval(3600)
        event.timeZone = referenceCity.timeZone
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(event, span: .thisEvent)
        return "Added \"\(event.title ?? title)\" to Apple Calendar for \(referenceCity.formattedShortDate(at: startDate)) at \(referenceCity.formattedTime(at: startDate, use24Hour: use24Hour))."
        #else
        return "Calendar snippet prepared:\n\(notes)"
        #endif
    }
}
