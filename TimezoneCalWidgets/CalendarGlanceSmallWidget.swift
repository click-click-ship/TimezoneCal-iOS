import SwiftUI
import WidgetKit

/// Widget 1: "Calendar Glance Trio" (`systemSmall` 2x2)
/// Styled after Apple's Calendar widget with a bold Calendar Red date header + 3 pinned cities.
public struct CalendarGlanceSmallWidget: Widget {
    public let kind: String = "CalendarGlanceSmallWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimezoneWidgetProvider()) { entry in
            CalendarGlanceSmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calendar Glance Trio")
        .description("Apple Calendar style header with your home time and 3 pinned world cities.")
        .supportedFamilies([.systemSmall])
    }
}

public struct CalendarGlanceSmallWidgetView: View {
    public let entry: TimezoneWidgetEntry

    public var body: some View {
        let displayDate = entry.effectiveDate

        VStack(alignment: .leading, spacing: 6) {
            // Apple Calendar Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.homeCity.formattedShortDate(at: displayDate).uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.red)

                    Text("\(entry.homeCity.shortCode) \(entry.homeCity.formattedTime(at: displayDate, use24Hour: entry.use24HourFormat))")
                        .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "calendar")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
            }

            Divider()

            VStack(spacing: 6) {
                ForEach(entry.pinnedCities.prefix(3)) { city in
                    let phase = city.dayPhase(at: displayDate)
                    HStack(spacing: 5) {
                        Text(city.shortCode)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .frame(width: 30, alignment: .leading)

                        Image(systemName: phase.symbolName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(
                                phase == .working ? .green : (phase == .sleeping ? .indigo : .orange)
                            )

                        Spacer(minLength: 2)

                        Text(city.formattedTime(at: displayDate, use24Hour: entry.use24HourFormat))
                            .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}
