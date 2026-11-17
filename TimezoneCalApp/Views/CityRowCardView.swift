import SwiftUI

/// Displays a single city's timezone card with compact Apple Calendar styling, Day/Night phase pills,
/// 1-Tap Reference switching, and an interactive World Time Buddy-inspired 24-hour scrubbing band.
public struct CityRowCardView: View {
    @EnvironmentObject private var store: TimezoneStore

    public let city: CityTimezone
    public let isHomeCity: Bool

    private struct AlignedHourItem: Identifiable {
        let refHour: Int
        let cityHour: Int
        let isGolden: Bool
        var id: Int { refHour }
    }

    private var isReference: Bool {
        store.activeReferenceCityID == city.id
    }

    private var phase: DayPhase {
        city.dayPhase(at: store.selectedDate)
    }

    private var selectedMinuteInCity: Int {
        city.localComponents(at: store.selectedDate).minute ?? 0
    }

    private var activeRefHour: Int {
        store.referenceCity.localComponents(at: store.selectedDate).hour ?? 12
    }

    /// Generates the 24 local hours for this city mapped onto the reference city's 0...23 hour strip.
    private var alignedHoursForReferenceDay: [AlignedHourItem] {
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
            return AlignedHourItem(refHour: refHour, cityHour: cHour, isGolden: golden)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            topHeaderRow
            scrubbingBandRow
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(cardBackground)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }

    // MARK: - Subviews

    private var topHeaderRow: some View {
        HStack(alignment: .center, spacing: 8) {
            cityIdentityColumn
            Spacer(minLength: 4)
            convertedTimeColumn
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.setReferenceCity(city)
        }
    }

    private var cityIdentityColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            cityTitleLine
            citySubtitleLine
        }
    }

    private var cityTitleLine: some View {
        HStack(spacing: 5) {
            Text(city.flagEmoji)
                .font(.system(size: 16))

            Text(city.cityName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if isHomeCity {
                Label("HOME", systemImage: "house.fill")
                    .font(.system(size: 8.5, weight: .heavy))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color.blue.opacity(0.16), in: Capsule())
                    .foregroundStyle(.blue)
            }

            offsetBadge
        }
    }

    private var offsetBadge: some View {
        let badgeText = city.formattedOffsetBadge(
            relativeTo: store.referenceCity,
            at: store.selectedDate,
            isReference: isReference
        )
        return Text(badgeText)
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                isReference ? Color.red : Color(.tertiarySystemFill),
                in: Capsule()
            )
            .foregroundStyle(isReference ? .white : .secondary)
    }

    private var citySubtitleLine: some View {
        let dayLabel = city.relativeDayLabel(relativeTo: store.referenceCity, at: store.selectedDate)
        let isToday = dayLabel == "Today"

        return HStack(spacing: 4) {
            Text("\(city.countryOrRegion) • \(city.abbreviation(at: store.selectedDate))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("• \(dayLabel)")
                .font(.caption2.weight(isToday ? .regular : .bold))
                .foregroundStyle(isToday ? .secondary : .red)
        }
    }

    private var convertedTimeColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(city.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat))
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(isReference ? .red : .primary)

            phasePill
        }
    }

    private var phasePill: some View {
        HStack(spacing: 3) {
            Image(systemName: phase.symbolName)
                .font(.system(size: 9, weight: .bold))
            Text(phase.rawValue)
                .font(.system(size: 9.5, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 1.5)
        .background(phaseBackgroundTint(for: phase), in: Capsule())
        .foregroundStyle(phaseForegroundTint(for: phase))
    }

    private var scrubbingBandRow: some View {
        GeometryReader { geo in
            let totalWidth = max(1, geo.size.width)
            let aligned = alignedHoursForReferenceDay

            ZStack(alignment: .leading) {
                HStack(spacing: 1) {
                    ForEach(aligned) { item in
                        hourCell(for: item)
                    }
                }

                redIndicatorLine(totalWidth: totalWidth)
            }
            .gesture(scrubGesture(totalWidth: totalWidth))
        }
        .frame(height: 23)
    }

    private func hourCell(for item: AlignedHourItem) -> some View {
        let cellPhase = DayPhase.from(hour: item.cityHour)
        let isSelectedColumn = item.refHour == activeRefHour
        let textColor: Color = isSelectedColumn ? .white : timelineCellTextColor(for: cellPhase)
        let fillColor: Color = isSelectedColumn ? Color.red : timelineCellBackgroundColor(for: cellPhase)

        return VStack(spacing: 1) {
            Circle()
                .fill(item.isGolden ? Color.green : Color.clear)
                .frame(width: 3.5, height: 3.5)

            Text("\(item.cityHour)")
                .font(.system(size: 8.5, weight: isSelectedColumn ? .heavy : .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .fill(fillColor)
        )
    }

    private func redIndicatorLine(totalWidth: CGFloat) -> some View {
        let progress = (Double(activeRefHour) + Double(selectedMinuteInCity) / 60.0) / 24.0
        let xOffset = min(max(0, totalWidth * progress), totalWidth - 2)

        return Rectangle()
            .fill(Color.red)
            .frame(width: 2, height: 24)
            .offset(x: xOffset)
            .allowsHitTesting(false)
    }

    private func scrubGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let fraction = min(max(0, value.location.x / totalWidth), 0.999)
                let totalMinutesInDay = Int((fraction * 24.0 * 60.0).rounded())
                let snappedMinutes = (totalMinutesInDay / 15) * 15
                let hour = snappedMinutes / 60
                let minute = snappedMinutes % 60
                store.setTimeInReferenceCity(hour: hour, minute: minute)
            }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isReference ? Color.red.opacity(0.75) : Color(.separator).opacity(0.25),
                        lineWidth: isReference ? 1.8 : 0.8
                    )
            )
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
