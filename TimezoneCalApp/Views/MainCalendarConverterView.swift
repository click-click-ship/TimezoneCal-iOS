import SwiftUI

/// Main TabView coordinating the Apple Calendar Timezone Converter, Share Times, and the Interactive Widget Studio.
public struct MainCalendarConverterView: View {
    @EnvironmentObject private var store: TimezoneStore

    @State private var activeCitySheetMode: AddCitySheetView.SelectionMode?
    @State private var showManageGroupsSheet: Bool = false
    @State private var editMode: EditMode = .inactive

    public init() {}

    public var body: some View {
        TabView {
            // MARK: Tab 1 — Primary iOS Calendar Timezone Converter
            converterTab
                .tabItem {
                    Label("Converter", systemImage: "calendar.day.timeline.left")
                }

            // MARK: Tab 2 (Middle) — Share Times
            ShareTimesView()
                .tabItem {
                    Label("Share Times", systemImage: "square.and.arrow.up")
                }

            // MARK: Tab 3 — Interactive WidgetKit Studio & Configurator
            WidgetGalleryPreviewView()
                .tabItem {
                    Label("Widgets", systemImage: "square.grid.2x2.fill")
                }
        }
        .tint(.red)
        .sheet(item: $activeCitySheetMode) { mode in
            AddCitySheetView(initialMode: mode)
        }
        .sheet(isPresented: $showManageGroupsSheet) {
            ManageGroupsSheetView()
        }
    }

    private var converterTab: some View {
        VStack(spacing: 0) {
            // Top Apple Calendar Header + Week Scrubber + Group Bar + Top-Right Edit & Add Buttons
            CalendarHeaderView(
                activeCitySheetMode: $activeCitySheetMode,
                showManageGroupsSheet: $showManageGroupsSheet,
                editMode: $editMode
            )

            // Dynamic Editable List of Target Cities (Home section removed for maximum card visibility)
            List {
                Section {
                    ForEach(store.activeCities) { city in
                        CityRowCardView(city: city, isHomeCity: city.id == store.homeCity.id)
                            .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.removeCity(city)
                                } label: {
                                    Label("Remove", systemImage: "trash.fill")
                                }

                                Button {
                                    store.toggleWidgetPin(for: city)
                                } label: {
                                    Label(
                                        store.widgetPinnedCityIDs.contains(city.id) ? "Unpin Widget" : "Pin to Widget",
                                        systemImage: "pin.fill"
                                    )
                                }
                                .tint(.orange)
                            }
                    }
                    .onDelete(perform: store.removeCities)
                    .onMove(perform: store.moveCities)
                } header: {
                    HStack {
                        Text("\(store.activeGroup.name.uppercased()) (\(store.activeCities.count)) • TAP CARD FOR REF")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        if editMode == .active {
                            Button {
                                withAnimation(.snappy) {
                                    editMode = .inactive
                                }
                            } label: {
                                Text("Done")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .environment(\.editMode, $editMode)

            // Bottom Frosted-Glass Time Scrubber, Tappable Home Selector & Reset to Now Bar
            TimeScrubberControlView(activeCitySheetMode: $activeCitySheetMode)
        }
        .background(Color(.systemGroupedBackground))
    }
}
