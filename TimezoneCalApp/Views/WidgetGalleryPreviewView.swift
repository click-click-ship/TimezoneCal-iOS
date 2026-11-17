import SwiftUI

/// Interactive In-App Widget Studio & Configurator.
/// Previews all 4 iOS WidgetKit designs (Small Calendar Glance Trio, Medium Overlap Card,
/// Medium 6-Hour Timeline Strip, and Lock Screen Widgets) and lets users pin up to 3 cities.
public struct WidgetGalleryPreviewView: View {
    @EnvironmentObject private var store: TimezoneStore

    private var previewDate: Date {
        Calendar.current.date(byAdding: .hour, value: store.widgetHourOffset, to: store.selectedDate) ?? store.selectedDate
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Pinned Widget Cities Selector
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Pinned Widget Cities (Pick up to 3)", systemImage: "pin.fill")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(store.widgetPinnedCityIDs.count)/3")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.15), in: Capsule())
                                .foregroundStyle(.red)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                let candidateCities = Array(Set(store.groups.flatMap(\.cities) + [
                                    CityCatalog.newYork,
                                    CityCatalog.london,
                                    CityCatalog.tokyo,
                                    CityCatalog.sydney,
                                    CityCatalog.paris
                                ]))

                                ForEach(candidateCities) { city in
                                    let isPinned = store.widgetPinnedCityIDs.contains(city.id)
                                    Button {
                                        withAnimation(.snappy) {
                                            store.toggleWidgetPin(for: city)
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Text(city.flagEmoji)
                                            Text(city.cityName)
                                                .font(.system(size: 13, weight: .semibold))
                                            if isPinned {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 12))
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(
                                            isPinned ? Color.red : Color(.secondarySystemGroupedBackground),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(isPinned ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: Widget 1 — "Calendar Glance Trio" (Small 2x2)
                    VStack(alignment: .leading, spacing: 8) {
                        widgetSectionHeader(
                            title: "1. Calendar Glance Trio",
                            subtitle: "Small (2×2) • Apple Calendar red header + 3 pinned cities"
                        )

                        HStack {
                            Spacer()
                            smallCalendarGlanceWidgetCard
                                .frame(width: 170, height: 170)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)

                    // MARK: Widget 2 — "Multi-Zone Overlap Card" (Medium 4x2)
                    VStack(alignment: .leading, spacing: 8) {
                        widgetSectionHeader(
                            title: "2. Multi-Zone Overlap Card",
                            subtitle: "Medium (4×2) • Home reference + 3 side-by-side city cards with working status dots"
                        )

                        mediumOverlapWidgetCard
                            .frame(maxWidth: .infinity)
                            .frame(height: 165)
                    }
                    .padding(.horizontal, 16)

                    // MARK: Widget 3 — "6-Hour Timeline Strip" (Medium 4x2 Interactive)
                    VStack(alignment: .leading, spacing: 8) {
                        widgetSectionHeader(
                            title: "3. Interactive 6-Hour Timeline Strip",
                            subtitle: "Medium (4×2) • Mini World Time Buddy grid with iOS 17+ interactive +1h / -1h buttons"
                        )

                        mediumSixHourTimelineWidgetCard
                            .frame(maxWidth: .infinity)
                            .frame(height: 178)
                    }
                    .padding(.horizontal, 16)

                    // MARK: Widget 4 — Lock Screen Circular / Rectangular Widgets
                    VStack(alignment: .leading, spacing: 8) {
                        widgetSectionHeader(
                            title: "4. iOS Lock Screen Widgets",
                            subtitle: "accessoryRectangular & accessoryInline • Instant Lock Screen glance"
                        )

                        lockScreenWidgetPreviewCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("iOS Widgets Studio")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Widget Preview Renderers

    private var smallCalendarGlanceWidgetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Apple Calendar Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(store.homeCity.formattedShortDate(at: previewDate).uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.red)
                    Text("\(store.homeCity.shortCode) \(store.homeCity.formattedTime(at: previewDate, use24Hour: store.use24HourFormat))")
                        .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "calendar")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
            }

            Divider()

            VStack(spacing: 7) {
                ForEach(store.widgetCities.prefix(3)) { city in
                    let phase = city.dayPhase(at: previewDate)
                    HStack(spacing: 6) {
                        Text(city.shortCode)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .frame(width: 32, alignment: .leading)

                        Image(systemName: phase.symbolName)
                            .font(.system(size: 10))
                            .foregroundStyle(phase == .working ? .green : (phase == .sleeping ? .indigo : .orange))

                        Spacer()

                        Text(city.formattedTime(at: previewDate, use24Hour: store.use24HourFormat))
                            .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    private var mediumOverlapWidgetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("\(store.homeCity.cityName) (Home)")
                        .font(.system(size: 12, weight: .bold))
                    Text(store.homeCity.formattedTime(at: previewDate, use24Hour: store.use24HourFormat))
                        .font(.system(size: 12, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(.red)
                }
                Spacer()
                Text(store.homeCity.formattedShortDate(at: previewDate).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(store.widgetCities.prefix(3)) { city in
                    let phase = city.dayPhase(at: previewDate)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(city.flagEmoji) \(city.shortCode)")
                                .font(.system(size: 12, weight: .bold))
                            Spacer()
                            Circle()
                                .fill(phase == .working ? Color.green : (phase == .sleeping ? Color.indigo : Color.orange))
                                .frame(width: 7, height: 7)
                        }

                        Text(city.formattedTime(at: previewDate, use24Hour: store.use24HourFormat))
                            .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        HStack(spacing: 4) {
                            Image(systemName: phase.symbolName)
                                .font(.system(size: 9))
                            Text(city.formattedOffsetBadge(relativeTo: store.homeCity, at: previewDate))
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    private var mediumSixHourTimelineWidgetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    store.widgetHourOffset == 0
                        ? "Next 6 Hours (Live)"
                        : "Shifted \(store.widgetHourOffset > 0 ? "+\(store.widgetHourOffset)h" : "\(store.widgetHourOffset)h")",
                    systemImage: "calendar.day.timeline.left"
                )
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.red)

                Spacer()

                // Interactive iOS 17+ Widget Button Preview
                HStack(spacing: 4) {
                    Button {
                        store.widgetHourOffset -= 1
                    } label: {
                        Text("-1h")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.widgetHourOffset = 0
                    } label: {
                        Text("Now")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.16), in: Capsule())
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.widgetHourOffset += 1
                    } label: {
                        Text("+1h")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 6) {
                ForEach(store.widgetCities.prefix(3)) { city in
                    HStack(spacing: 6) {
                        Text("\(city.flagEmoji) \(city.shortCode)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .frame(width: 52, alignment: .leading)

                        HStack(spacing: 3) {
                            ForEach(0..<6, id: \.self) { offset in
                                let slotDate = Calendar.current.date(byAdding: .hour, value: offset, to: previewDate) ?? previewDate
                                let hour = city.localComponents(at: slotDate).hour ?? 12
                                let phase = DayPhase.from(hour: hour)

                                Text(city.compactHourLabel(forHour: hour, use24Hour: store.use24HourFormat))
                                    .font(.system(size: 10, weight: offset == 0 ? .heavy : .semibold, design: .rounded).monospacedDigit())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    private var lockScreenWidgetPreviewCard: some View {
        VStack(spacing: 12) {
            // Inline Lock Screen Pill
            let topTwo = store.widgetCities.prefix(2)
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.caption2)
                Text(
                    topTwo.map {
                        "\($0.shortCode) \($0.formattedTime(at: previewDate, use24Hour: true)) \($0.dayPhase(at: previewDate).emoji)"
                    }.joined(separator: "  •  ")
                )
                .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())

            // Rectangular Lock Screen Widget
            VStack(alignment: .leading, spacing: 4) {
                Text("WORLD CALENDAR • \(store.homeCity.shortCode)")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)

                ForEach(store.widgetCities.prefix(3)) { city in
                    HStack {
                        Text(city.cityName)
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                        Image(systemName: city.dayPhase(at: previewDate).symbolName)
                            .font(.system(size: 10))
                        Text(city.formattedTime(at: previewDate, use24Hour: store.use24HourFormat))
                            .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    }
                }
            }
            .padding(12)
            .frame(width: 220)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.45), Color.black.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .foregroundStyle(.white)
    }

    private func widgetSectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.bold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
