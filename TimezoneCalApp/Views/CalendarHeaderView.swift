import SwiftUI

/// Authentic iOS Calendar-styled top header with expandable Month Picker, 7-Day Week Strip,
/// Group Preset Switcher, Edit toggle, and Smart Daylight Saving Time (DST) Warning Banner.
public struct CalendarHeaderView: View {
    @EnvironmentObject private var store: TimezoneStore

    @Binding var activeCitySheetMode: AddCitySheetView.SelectionMode?
    @Binding var showManageGroupsSheet: Bool
    @Binding var editMode: EditMode
    @State private var isMonthCalendarExpanded: Bool = false

    private var referenceCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = store.referenceCity.timeZone
        return cal
    }

    /// Generates the 7 days surrounding `store.selectedDate` in the active reference timezone.
    private var weekDays: [Date] {
        let cal = referenceCalendar
        let startOfDay = cal.startOfDay(for: store.selectedDate)
        let weekday = cal.component(.weekday, from: startOfDay) // 1 = Sun ... 7 = Sat
        let sundayOffset = -(weekday - 1)
        guard let sunday = cal.date(byAdding: .day, value: sundayOffset, to: startOfDay) else {
            return [store.selectedDate]
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: sunday) }
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.timeZone = store.referenceCity.timeZone
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: store.selectedDate)
    }

    private var fullSelectedDateSubtitle: String {
        let formatter = DateFormatter()
        formatter.timeZone = store.referenceCity.timeZone
        formatter.dateFormat = "EEEE, MMM d"
        return "\(formatter.string(from: store.selectedDate)) • \(store.referenceCity.cityName)"
    }

    public var body: some View {
        VStack(spacing: 6) {
            // MARK: Top Bar — Month/Year Dropdown, Appearance Toggle, Edit Button & Add City (+)
            HStack(alignment: .center, spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        isMonthCalendarExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.red)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 4) {
                                Text(monthYearTitle)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)

                                Image(systemName: isMonthCalendarExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.red)
                            }
                            Text(fullSelectedDateSubtitle)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Auto Day / Night Mode & Format Menu
                Menu {
                    Section("Appearance (Auto Day/Night)") {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Button {
                                store.appearanceMode = mode
                            } label: {
                                Label(
                                    mode.rawValue,
                                    systemImage: store.appearanceMode == mode ? "checkmark.circle.fill" : mode.symbolName
                                )
                            }
                        }
                    }
                    Section("Time Format") {
                        Button {
                            store.use24HourFormat.toggle()
                        } label: {
                            Label(
                                store.use24HourFormat ? "Switch to 12-Hour (AM/PM)" : "Switch to 24-Hour (Military)",
                                systemImage: "clock"
                            )
                        }
                    }
                } label: {
                    Image(systemName: store.appearanceMode.symbolName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }

                // Edit / Reorder Cities Button (Top-Right Corner)
                Button {
                    withAnimation(.snappy) {
                        editMode = (editMode == .active) ? .inactive : .active
                    }
                } label: {
                    Image(systemName: editMode == .active ? "checkmark" : "pencil")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(editMode == .active ? .white : .primary)
                        .frame(width: 32, height: 32)
                        .background(
                            editMode == .active ? Color.red : Color(.tertiarySystemFill),
                            in: Circle()
                        )
                }
                .accessibilityLabel(editMode == .active ? "Done Editing" : "Edit Cities")

                // Add City Quick Action
                Button {
                    activeCitySheetMode = .addToGroup
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red, in: Circle())
                }
                .accessibilityLabel("Add City")
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            // MARK: Apple Calendar 7-Day Week Strip
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.timeIntervalSince1970) { day in
                    let isSelected = referenceCalendar.isDate(day, inSameDayAs: store.selectedDate)
                    let isToday = referenceCalendar.isDateInToday(day)

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            store.selectCalendarDay(day)
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Text(shortWeekdaySymbol(for: day))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(isSelected ? .red : .secondary)

                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(isToday ? Color.red : Color.primary)
                                        .frame(width: 28, height: 28)
                                } else if isToday {
                                    Circle()
                                        .strokeBorder(Color.red.opacity(0.55), lineWidth: 1.5)
                                        .frame(width: 28, height: 28)
                                }

                                Text("\(referenceCalendar.component(.day, from: day))")
                                    .font(.system(size: 14, weight: isSelected || isToday ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(
                                        isSelected
                                            ? Color(.systemBackground)
                                            : (isToday ? Color.red : Color.primary)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)

            // MARK: Expandable Full Graphical Month Calendar
            if isMonthCalendarExpanded {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { store.selectedDate },
                        set: { store.selectCalendarDay($0) }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // MARK: City Group / Preset Pill Bar ("Work Team", "Family", "Travel")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(store.groups) { group in
                        let isSelected = group.id == store.selectedGroupID
                        Button {
                            withAnimation(.snappy) {
                                store.selectedGroupID = group.id
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: group.iconName)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(group.name)
                                    .font(.system(size: 12, weight: .semibold))
                                Text("\(group.cities.count)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(
                                        isSelected ? Color.white.opacity(0.24) : Color(.tertiarySystemFill),
                                        in: Capsule()
                                    )
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                isSelected ? Color.red : Color(.secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showManageGroupsSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Groups")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            }

            // MARK: Smart Daylight Saving Time (DST) Transition Alert Banner
            let warnings = store.activeDSTWarnings
            if !warnings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(warnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(warning)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.orange.opacity(0.45), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .opacity(0.6)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func shortWeekdaySymbol(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = store.referenceCity.timeZone
        formatter.dateFormat = "EEEEE" // Single letter S M T W T F S
        return formatter.string(from: date).uppercased()
    }
}
