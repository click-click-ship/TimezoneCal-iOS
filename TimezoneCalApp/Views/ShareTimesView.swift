import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Dedicated middle-tab view for sharing formatted multi-timezone meeting availability.
public struct ShareTimesView: View {
    @EnvironmentObject private var store: TimezoneStore

    @State private var meetingTitle: String = "Proposed Meeting"
    @State private var durationMinutes: Int = 60
    @State private var didCopyRecently: Bool = false

    private let durationOptions: [(label: String, minutes: Int)] = [
        ("30m", 30),
        ("1h", 60),
        ("90m", 90),
        ("2h", 120)
    ]

    public init() {}

    private var formattedSnippet: String {
        CalendarExportService.buildShareSnippet(
            title: meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Proposed Meeting" : meetingTitle,
            startDate: store.selectedDate,
            durationMinutes: durationMinutes,
            cities: store.allComparedCities,
            referenceCity: store.referenceCity,
            use24Hour: store.use24HourFormat
        )
    }

    public var body: some View {
        NavigationStack {
            List {
                // MARK: Meeting Configuration
                Section("Meeting Details") {
                    TextField("Meeting Title", text: $meetingTitle)

                    HStack {
                        Text("Duration")
                        Spacer()
                        Picker("Duration", selection: $durationMinutes) {
                            ForEach(durationOptions, id: \.minutes) { option in
                                Text(option.label).tag(option.minutes)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                    }

                    LabeledContent(
                        "Selected Date",
                        value: store.referenceCity.formattedShortDate(at: store.selectedDate)
                    )
                    LabeledContent(
                        "Home (\(store.homeCity.shortCode))",
                        value: store.homeCity.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat)
                    )
                }

                // MARK: Live Multi-Timezone Preview
                Section("Message Preview (\(store.activeGroup.name))") {
                    Text(formattedSnippet)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                }

                // MARK: Share & Copy Actions
                Section {
                    ShareLink(item: formattedSnippet) {
                        HStack {
                            Spacer()
                            Label("Share Times", systemImage: "square.and.arrow.up")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.red)
                    .foregroundStyle(.white)

                    Button {
                        copySnippet()
                    } label: {
                        HStack {
                            Spacer()
                            Label(
                                didCopyRecently ? "Copied to Clipboard!" : "Copy Formatted Text",
                                systemImage: didCopyRecently ? "checkmark.circle.fill" : "doc.on.doc"
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(didCopyRecently ? .green : .red)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Share Times")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func copySnippet() {
        #if canImport(UIKit)
        UIPasteboard.general.string = formattedSnippet
        #endif
        withAnimation(.snappy) {
            didCopyRecently = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                didCopyRecently = false
            }
        }
    }
}
