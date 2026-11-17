import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Frosted-glass bottom control bar with "Golden Hours" Overlap detector pill,
/// tappable Home City selector (with visual Home badge), 15-minute precision time slider,
/// -1h/+1h quick steps, and 1-Tap "Reset to Now".
public struct TimeScrubberControlView: View {
    @EnvironmentObject private var store: TimezoneStore

    @Binding var activeCitySheetMode: AddCitySheetView.SelectionMode?

    public init(activeCitySheetMode: Binding<AddCitySheetView.SelectionMode?>) {
        _activeCitySheetMode = activeCitySheetMode
    }

    private var currentMinutesInReferenceDay: Double {
        let comps = store.referenceCity.localComponents(at: store.selectedDate)
        let h = comps.hour ?? 12
        let m = comps.minute ?? 0
        return Double(h * 60 + m)
    }

    private var isScrubbingInHome: Bool {
        store.activeReferenceCityID == store.homeCity.id
    }

    public var body: some View {
        VStack(spacing: 7) {
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
                            .font(.system(size: 11, weight: .bold))
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
                            .font(.system(size: 11.5))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Text("Jump")
                            .font(.system(size: 10.5, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.green, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5.5)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.green.opacity(0.13))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.green.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            // MARK: 2. Tappable Home Selector + Active Reference Readout & -1h/+1h Stepper Buttons
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        // Interactive Home Selection Pill (opens Change Home City search filter)
                        Button {
                            activeCitySheetMode = .setHomeCity
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 9.5, weight: .bold))
                                Text("HOME: \(store.homeCity.cityName.uppercased())")
                                    .font(.system(size: 10, weight: .heavy))
                                    .lineLimit(1)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 8.5, weight: .bold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.14), in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.blue.opacity(0.35), lineWidth: 0.8)
                            )
                            .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Change Home City, currently \(store.homeCity.cityName)")

                        if !isScrubbingInHome {
                            Text("• REF: \(store.referenceCity.cityName.uppercased())")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(store.referenceCity.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat))
                            .font(.system(size: 19, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.red)

                        Text(store.referenceCity.abbreviation(at: store.selectedDate))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Quick Step Buttons (-1h, +1h only)
                HStack(spacing: 6) {
                    stepButton(label: "-1h", minutes: -60)
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

            // MARK: 4. 1-Tap "Reset to Now" Button
            Button {
                triggerHaptic()
                store.resetToNow()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12, weight: .bold))
                    Text("Reset to Now")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    (store.isScrubbingCustomTime || !isScrubbingInHome)
                        ? Color.red
                        : Color(.tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
                .foregroundStyle(
                    (store.isScrubbingCustomTime || !isScrubbingInHome)
                        ? .white
                        : .primary
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func stepButton(label: String, minutes: Int) -> some View {
        Button {
            triggerHaptic()
            store.shiftSelectedTime(byMinutes: minutes)
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 11)
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
