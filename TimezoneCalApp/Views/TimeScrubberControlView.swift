import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Frosted-glass bottom control bar with "Golden Hours" Overlap detector pill,
/// 15-minute precision time slider, quick step buttons, ShareLink, and 1-Tap Apple Calendar (`EventKit`) export.
public struct TimeScrubberControlView: View {
    @EnvironmentObject private var store: TimezoneStore

    @State private var showCalendarExportAlert: Bool = false
    @State private var calendarExportMessage: String = ""
    @State private var meetingTitleInput: String = "Global Team Sync"
    @State private var showTitlePromptSheet: Bool = false

    private var currentMinutesInReferenceDay: Double {
        let comps = store.referenceCity.localComponents(at: store.selectedDate)
        let h = comps.hour ?? 12
        let m = comps.minute ?? 0
        return Double(h * 60 + m)
    }

    public var body: some View {
        VStack(spacing: 10) {
            // MARK: 1. "Golden Hours" Best Overlap Detector Pill
            if let window = store.bestGoldenOverlapWindow {
                Button {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        store.setTimeInReferenceCity(hour: window.startHourInReference, minute: 0)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.green)

                        let startLabel = store.referenceCity.compactHourLabel(
                            forHour: window.startHourInReference,
                            use24Hour: store.use24HourFormat
                        )
                        let endLabel = store.referenceCity.compactHourLabel(
                            forHour: window.endHourInReference + 1,
                            use24Hour: store.use24HourFormat
                        )

                        Text("Golden Hours (\(window.matchingCityCount)/\(window.totalCityCount) awake): **\(startLabel) – \(endLabel) \(store.referenceCity.shortCode)**")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("Jump")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.13))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.green.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            // MARK: 2. Active Reference Readout & Quick Stepper Buttons
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("SCRUBBING IN \(store.referenceCity.cityName.uppercased())")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text(store.referenceCity.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat))
                        .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.red)
                }

                Spacer()

                // Quick Step Buttons (-1h, -15m, +15m, +1h)
                HStack(spacing: 6) {
                    stepButton(label: "-1h", minutes: -60)
                    stepButton(label: "-15m", minutes: -15)
                    stepButton(label: "+15m", minutes: 15)
                    stepButton(label: "+1h", minutes: 60)
                }
            }

            // MARK: 3. Continuous 24-Hour Slider (15-Minute Increments)
            Slider(
                value: Binding(
                    get: { currentMinutesInReferenceDay },
                    set: { newValue in
                        let snapped = Int((newValue / 15.0).rounded()) * 15
                        let clamped = max(0, min(23 * 60 + 45, snapped))
                        let newHour = clamped / 60
                        let newMinute = clamped % 60
                        if clamped != Int(currentMinutesInReferenceDay) {
                            triggerHaptic()
                            store.setTimeInReferenceCity(hour: newHour, minute: newMinute)
                        }
                    }
                ),
                in: 0...(23 * 60 + 45),
                step: 15
            )
            .tint(.red)

            // MARK: 4. 1-Tap Share Snippet & Add to Apple Calendar Bar
            HStack(spacing: 10) {
                let snippet = CalendarExportService.buildShareSnippet(
                    title: meetingTitleInput,
                    startDate: store.selectedDate,
                    durationMinutes: 60,
                    cities: store.allComparedCities,
                    referenceCity: store.referenceCity,
                    use24Hour: store.use24HourFormat
                )

                ShareLink(item: snippet) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .bold))
                        Text("Share Times")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.primary)
                }

                Button {
                    showTitlePromptSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Add to Calendar")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
        .alert("Apple Calendar", isPresented: $showCalendarExportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(calendarExportMessage)
        }
        .sheet(isPresented: $showTitlePromptSheet) {
            NavigationStack {
                Form {
                    Section("Meeting Details") {
                        TextField("Meeting Title", text: $meetingTitleInput)
                        LabeledContent("Date", value: store.referenceCity.formattedShortDate(at: store.selectedDate))
                        LabeledContent(
                            "Start Time (\(store.referenceCity.cityName))",
                            value: store.referenceCity.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat)
                        )
                    }

                    Section("Converted Timezone Breakdown") {
                        ForEach(store.allComparedCities) { city in
                            HStack {
                                Text("\(city.flagEmoji) \(city.cityName)")
                                Spacer()
                                Text(city.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat))
                                    .font(.body.monospacedDigit().weight(.semibold))
                                Text(city.abbreviation(at: store.selectedDate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Add to Calendar")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showTitlePromptSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save Event") {
                            showTitlePromptSheet = false
                            Task {
                                do {
                                    calendarExportMessage = try await CalendarExportService.addEventToAppleCalendar(
                                        title: meetingTitleInput,
                                        startDate: store.selectedDate,
                                        durationMinutes: 60,
                                        cities: store.allComparedCities,
                                        referenceCity: store.referenceCity,
                                        use24Hour: store.use24HourFormat
                                    )
                                } catch {
                                    calendarExportMessage = error.localizedDescription
                                }
                                showCalendarExportAlert = true
                            }
                        }
                        .fontWeight(.bold)
                        .tint(.red)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func stepButton(label: String, minutes: Int) -> some View {
        Button {
            triggerHaptic()
            store.shiftSelectedTime(byMinutes: minutes)
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill), in: Capsule())
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}
