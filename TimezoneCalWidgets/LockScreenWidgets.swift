import SwiftUI
import WidgetKit

/// Widget 4: Lock Screen Circular / Rectangular & Inline Widgets (`accessoryRectangular` & `accessoryInline`)
public struct LockScreenTimezoneWidget: Widget {
    public let kind: String = "LockScreenTimezoneWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimezoneWidgetProvider()) { entry in
            LockScreenTimezoneWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Lock Screen World Glance")
        .description("Ultra-compact 2 or 3 city timezone glance for your iOS Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

public struct LockScreenTimezoneWidgetView: View {
    @Environment(\.widgetFamily) private var family
    public let entry: TimezoneWidgetEntry

    public var body: some View {
        let displayDate = entry.effectiveDate

        switch family {
        case .accessoryInline:
            let topTwo = entry.pinnedCities.prefix(2)
            Text(
                topTwo.map {
                    "\($0.shortCode) \($0.formattedTime(at: displayDate, use24Hour: true)) \($0.dayPhase(at: displayDate).emoji)"
                }.joined(separator: " • ")
            )

        default:
            VStack(alignment: .leading, spacing: 2) {
                Text("WORLD • \(entry.homeCity.shortCode) \(entry.homeCity.formattedTime(at: displayDate, use24Hour: entry.use24HourFormat))")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)

                ForEach(entry.pinnedCities.prefix(3)) { city in
                    HStack(spacing: 4) {
                        Text(city.shortCode)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Spacer()
                        Image(systemName: city.dayPhase(at: displayDate).symbolName)
                            .font(.system(size: 10))
                        Text(city.formattedTime(at: displayDate, use24Hour: entry.use24HourFormat))
                            .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                    }
                }
            }
        }
    }
}
