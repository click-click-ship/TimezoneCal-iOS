import SwiftUI

/// Displays a single city's timezone card with Apple Calendar styling, Day/Night phase pills,
/// 1-Tap Reference switching, and an interactive World Time Buddy-inspired 24-hour scrubbing band.
public struct CityRowCardView: View {
    @EnvironmentObject private var store: TimezoneStore

    public let city: CityTimezone
    public let isHomeCity: Bool

    private var isReference: Bool {
        store.activeReferenceCityID == city.id
    }

    private var phase: DayPhase {
        city.dayPhase(at: store.selectedDate)
    }

    private var selectedHourInCity: Int {
        city.localComponents(at: store.selectedDate).hour ?? 12
    }

    private var selectedMinuteInCity: Int {
        city.localComponents(at: store.selectedDate).minute ?? 0
    }

    /// Generates the 24 local hours for this city mapped onto the reference city's 0...23 hour strip.
    private var alignedHoursForReferenceDay: [(refHour: Int, cityHour: Int, isGolden: Bool)] {
        var refCal = Calendar(identifier: .gregorian)
        refCal.timeZone = store.referenceCity.timeZone
        let baseComps = refCal.dateComponents([.year, .month, .day], from: store.selectedDate)
        let allCities = store.allComparedCities

        return (0..<24).map { refHour in
            var c = baseComps
            c.hour = refHour
            c.minute = 0
            let dateAtHour = refCal.date(from: c) ?? store.selectedDate
            let cHour = city.localComponents(at: dateAtHour).hour ?? refHour
            let golden = allCities.count >= 2 && allCities.allSatisfy { $0.isGoldenMeetingHour(at: dateAtHour) }
            return (refHour, cHour, golden)
        }
    }

    private var activeRefHour: Int {
        store.referenceCity.localComponents(at: store.selectedDate).hour ?? 12
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: Top Row — City Identity, Offset Badge, Converted Time & Day/Night Status
            HStack(alignment: .top, spacing: 10) {
                // Left: City Name, Flag, Role Badge & Country/Abbreviation
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(city.flagEmoji)
                            .font(.system(size: 18))

                        Text(city.cityName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if isHomeCity {
                            Label("HOME", systemImage: "house.fill")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.16), in: Capsule())
                                .foregroundStyle(.blue)
                        }

                        // Offset / Reference Badge
                        Text(city.formattedOffsetBadge(
                            relativeTo: store.referenceCity,
                            at: store.selectedDate,
                            isReference: isReference
                        ))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            isReference ? Color.red : Color(.tertiarySystemFill),
                            in: Capsule()
                        )
                        .foregroundStyle(isReference ? .white : .secondary)
                    }

                    HStack(spacing: 6) {
                        Text("\(city.countryOrRegion) • \(city.abbreviation(at: store.selectedDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        let dayLabel = city.relativeDayLabel(relativeTo: store.referenceCity, at: store.selectedDate)
                        Text("• \(dayLabel)")
                            .font(.caption.weight(dayLabel == "Today" ? .regular : .bold))
                            .foregroundStyle(dayLabel == "Today" ? .secondary : .red)
                    }
                }

                Spacer(minLength: 4)

                // Right: Converted Monospaced Time & Local Day/Night Pill
                VStack(alignment: .trailing, spacing: 4) {
                    Text(city.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat))
                        .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(isReference ? .red : .primary)

                    HStack(spacing: 4) {
                        Image(systemName: phase.symbolName)
                            .font(.system(size: 10, weight: .bold))
                        Text(phase.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(phaseBackgroundTint(for: phase), in: Capsule())
                    .foregroundStyle(phaseForegroundTint(for: phase))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                store.setReferenceCity(city)
            }

            // MARK: Bottom Row — Synchronized 24-Hour World Time Buddy Scrubbing Band
            GeometryReader { geo in
                let totalWidth = max(1, geo.size.width)
                let cellWidth = totalWidth / 24.0
                let aligned = alignedHoursForReferenceDay

                ZStack(alignment: .leading) {
                    HStack(spacing: 1) {
                        ForEach(aligned, id: \.refHour) { item in
                            let cellPhase = DayPhase.from(hour: item.cityHour)
                            let isSelectedColumn = item.refHour == activeRefHour

                            VStack(spacing: 1) {
                                // Golden Overlap Top Dot
                                Circle()
                                    .fill(item.isGolden ? Color.green : Color.clear)
                                    .frame(width: 4, height: 4)

                                Text("\(item.cityHour)")
                                    .font(.system(size: 9, weight: isSelectedColumn ? .heavy : .medium, design: .rounded).monospacedDigit())
                                    .foregroundStyle(
                                        isSelectedColumn
                                            ? .white
                                            : timelineCellTextColor(for: cellPhase)
                                    )
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(
                                        isSelectedColumn
                                            ? Color.red
                                            : timelineCellBackgroundColor(for: cellPhase)
                                    )
                            )
                        }
                    }

                    // Apple Calendar Red Vertical Indicator Hairline
                    let progress = (Double(activeRefHour) + Double(selectedMinuteInCity) / 60.0) / 24.0
                    let xOffset = min(max(0, totalWidth * progress), totalWidth - 2)

                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 34)
                        .offset(x: xOffset)
                        .allowsHitTesting(false)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let fraction = min(max(0, value.location.x / totalWidth), 0.999)
                            let totalMinutesInDay = Int((fraction * 24.0 * 60.0).rounded())
                            // Snap to 15-minute increments like Apple Calendar
                            let snappedMinutes = (totalMinutesInDay / 15) * 15
                            let hour = snappedMinutes / 60
                            let minute = snappedMinutes % 60
                            store.setTimeInReferenceCity(hour: hour, minute: minute)
                        }
                )
            }
            .frame(height: 32)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            isReference ? Color.red.opacity(0.75) : Color(.separator).opacity(0.25),
                            lineWidth: isReference ? 1.8 : 0.8
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Semantic Day/Night Styling Helpers

    private func phaseBackgroundTint(for phase: DayPhase) -> Color {
        switch phase {
        case .working:  return Color.green.opacity(0.15)
        case .morning:  return Color.orange.opacity(0.16)
        case .evening:  return Color.purple.opacity(0.16)
        case .sleeping: return Color.indigo.opacity(0.20)
        }
    }

    private func phaseForegroundTint(for phase: DayPhase) -> Color {
        switch phase {
        case .working:  return Color.green
        case .morning:  return Color.orange
        case .evening:  return Color.purple
        case .sleeping: return Color.indigo
        }
    }

    private func timelineCellBackgroundColor(for phase: DayPhase) -> Color {
        switch phase {
        case .working:
            return Color.green.opacity(0.20)
        case .morning, .evening:
            return Color.orange.opacity(0.14)
        case .sleeping:
            return Color.indigo.opacity(0.16)
        }
    }

    private func timelineCellTextColor(for phase: DayPhase) -> Color {
        switch phase {
        case .working:
            return .primary
        case .morning, .evening:
            return .secondary
        case .sleeping:
            return .secondary.opacity(0.75)
        }
    }
}
