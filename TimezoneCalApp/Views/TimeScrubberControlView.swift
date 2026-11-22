import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Frosted-glass bottom control bar with "Golden Hours" Overlap detector pill,
/// card-aligned Home City selector & Reference Time readout, 15-minute precision time slider,
/// and 1-Tap "Reset to Now".
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

            // MARK: 2. Card-Aligned Home City Selector (Left) & Active Reference Time (Right)
            HStack(alignment: .center, spacing: 8) {
                Button {
                    activeCitySheetMode = .setHomeCity
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(store.homeCity.flagEmoji)
                                .font(.system(size: 16))

                            Text(store.homeCity.cityName)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Label("HOME", systemImage: "house.fill")
                                .font(.system(size: 8.5, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.16), in: Capsule())
                                .foregroundStyle(.blue)

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(.blue)
                        }

                        HStack(spacing: 4) {
                            Text("\(store.homeCity.abbreviation(at: store.selectedDate)) • Tap to change")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            if !isScrubbingInHome {
                                Text("• Ref: \(store.referenceCity.cityName)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change Home City, currently \(store.homeCity.cityName)")

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(store.referenceCity.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat))
                        .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.red)

                    if isScrubbingInHome {
                        let phase = store.referenceCity.dayPhase(at: store.selectedDate)
                        HStack(spacing: 3) {
                            Image(systemName: phase.symbolName)
                                .font(.system(size: 9, weight: .bold))
                            Text(phase.rawValue)
                                .font(.system(size: 9.5, weight: .semibold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(phase.pillBackgroundColor, in: Capsule())
                        .foregroundStyle(phase.pillForegroundColor)
                    } else {
                        HStack(spacing: 4) {
                            Text("REF: \(store.referenceCity.shortCode)")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1.5)
                                .background(Color.red, in: Capsule())
                                .foregroundStyle(.white)

                            Text(store.referenceCity.abbreviation(at: store.selectedDate))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
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
                        ? AnyShapeStyle(Color.white)
                        : AnyShapeStyle(.primary)
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

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}
