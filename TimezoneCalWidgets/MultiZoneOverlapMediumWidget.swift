import SwiftUI
import WidgetKit

/// Widget 2: "Multi-Zone Overlap Card" (`systemMedium` 4x2)
/// Displays Home time in the header + 3 side-by-side city cards with working-hours status dots and +/- hour offsets.
public struct MultiZoneOverlapMediumWidget: Widget {
    public let kind: String = "MultiZoneOverlapMediumWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimezoneWidgetProvider()) { entry in
            MultiZoneOverlapMediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Multi-Zone Overlap Card")
        .description("Compare your Home Time against 3 cities side-by-side with work-hour status indicators.")
        .supportedFamilies([.systemMedium])
    }
}

public struct MultiZoneOverlapMediumWidgetView: View {
    public let entry: TimezoneWidgetEntry

    public var body: some View {
        let displayDate = entry.effectiveDate

        VStack(alignment: .leading, spacing: 8) {
            // Top Apple Calendar Header Bar
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 7, height: 7)

                    Text("\(entry.homeCity.cityName)")
                        .font(.system(size: 12, weight: .bold))

                    Text(entry.homeCity.formattedTime(at: displayDate, use24Hour: entry.use24HourFormat))
                        .font(.system(size: 12, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(.red)
                }

                Spacer()

                Text(entry.homeCity.formattedShortDate(at: displayDate).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            // 3 Side-by-Side City Columns
            HStack(spacing: 8) {
                ForEach(entry.pinnedCities.prefix(3)) { city in
                    let phase = city.dayPhase(at: displayDate)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("\(city.flagEmoji) \(city.shortCode)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                            Circle()
                                .fill(phase == .working ? Color.green : (phase == .sleeping ? Color.indigo : Color.orange))
                                .frame(width: 7, height: 7)
                        }

                        Text(city.formattedTime(at: displayDate, use24Hour: entry.use24HourFormat))
                            .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        HStack(spacing: 4) {
                            Image(systemName: phase.symbolName)
                                .font(.system(size: 9))
                            Text(city.formattedOffsetBadge(relativeTo: entry.homeCity, at: displayDate))
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground).opacity(0.75))
                    )
                }
            }
        }
    }
}
