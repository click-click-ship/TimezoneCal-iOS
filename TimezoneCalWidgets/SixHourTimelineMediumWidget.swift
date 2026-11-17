import AppIntents
import SwiftUI
import WidgetKit

/// Widget 3: "6-Hour Timeline Strip" (`systemMedium` 4x2 Interactive)
/// Mini World Time Buddy horizontal grid showing the next 6 hours across your top 3 cities,
/// complete with interactive iOS 17+ `-1h`, `Now`, and `+1h` buttons right on the Home Screen.
public struct SixHourTimelineMediumWidget: Widget {
    public let kind: String = "SixHourTimelineMediumWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimezoneWidgetProvider()) { entry in
            SixHourTimelineMediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("6-Hour Timeline Strip")
        .description("Interactive World Time Buddy 6-hour grid. Tap +1h or -1h right on your Home Screen.")
        .supportedFamilies([.systemMedium])
    }
}

public struct SixHourTimelineMediumWidgetView: View {
    public let entry: TimezoneWidgetEntry

    public var body: some View {
        let displayDate = entry.effectiveDate

        VStack(alignment: .leading, spacing: 7) {
            // Header + Interactive iOS 17 AppIntent Scrubbing Buttons
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.day.timeline.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.red)

                    Text(
                        entry.hourOffset == 0
                            ? "6-Hour Outlook (\(entry.homeCity.shortCode))"
                            : "Shifted \(entry.hourOffset > 0 ? "+\(entry.hourOffset)h" : "\(entry.hourOffset)h")"
                    )
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.primary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Button(intent: ShiftWidgetTimeIntent(deltaHours: -1)) {
                        Text("-1h")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .background(Color(.tertiarySystemFill), in: Capsule())

                    Button(intent: ResetWidgetTimeIntent()) {
                        Text("Now")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .background(Color.red.opacity(0.15), in: Capsule())

                    Button(intent: ShiftWidgetTimeIntent(deltaHours: 1)) {
                        Text("+1h")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .background(Color(.tertiarySystemFill), in: Capsule())
                }
            }

            // 3 Rows × 6 Hours Grid
            VStack(spacing: 5) {
                ForEach(entry.pinnedCities.prefix(3)) { city in
                    HStack(spacing: 6) {
                        Text("\(city.flagEmoji) \(city.shortCode)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .frame(width: 48, alignment: .leading)

                        HStack(spacing: 3) {
                            ForEach(0..<6, id: \.self) { offset in
                                let slotDate = Calendar.current.date(byAdding: .hour, value: offset, to: displayDate) ?? displayDate
                                let hour = city.localComponents(at: slotDate).hour ?? 12
                                let phase = DayPhase.from(hour: hour)

                                Text(city.compactHourLabel(forHour: hour, use24Hour: entry.use24HourFormat))
                                    .font(.system(size: 10, weight: offset == 0 ? .heavy : .semibold, design: .rounded).monospacedDigit())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(
                                                offset == 0
                                                    ? Color.red
                                                    : (phase == .working ? Color.green.opacity(0.22) : Color.indigo.opacity(0.16))
                                            )
                                    )
                                    .foregroundStyle(offset == 0 ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
                            }
                        }
                    }
                }
            }
        }
    }
}
