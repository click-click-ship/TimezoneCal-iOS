import SwiftUI

/// Main TabView coordinating the Apple Calendar Timezone Converter and the Interactive Widget Studio.
public struct MainCalendarConverterView: View {
    @EnvironmentObject private var store: TimezoneStore

    @State private var showAddCitySheet: Bool = false
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

            // MARK: Tab 2 — Interactive WidgetKit Studio & Configurator
            WidgetGalleryPreviewView()
                .tabItem {
                    Label("Widgets", systemImage: "square.grid.2x2.fill")
                }
        }
        .tint(.red)
        .sheet(isPresented: $showAddCitySheet) {
            AddCitySheetView()
        }
        .sheet(isPresented: $showManageGroupsSheet) {
            ManageGroupsSheetView()
        }
    }

    private var converterTab: some View {
        VStack(spacing: 0) {
            // Top Apple Calendar Header + Week Scrubber + Group Bar
            CalendarHeaderView(
                showAddCitySheet: $showAddCitySheet,
                showManageGroupsSheet: $showManageGroupsSheet
            )

            // Scrollable / Editable List of Cities
            List {
                // Section 1: Pinned Home Timezone Card
                Section {
                    CityRowCardView(city: store.homeCity, isHomeCity: true)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } header: {
                    HStack {
                        Text("HOME TIMEZONE • TAP ANY CARD TO SET AS REFERENCE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }

                // Section 2: Dynamic Editable List of Target Cities
                Section {
                    ForEach(store.activeCities) { city in
                        CityRowCardView(city: city, isHomeCity: false)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                        Text("\(store.activeGroup.name.uppercased()) CITIES (\(store.activeCities.count))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            withAnimation {
                                editMode = (editMode == .active) ? .inactive : .active
                            }
                        } label: {
                            Text(editMode == .active ? "Done" : "Reorder / Edit")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .environment(\.editMode, $editMode)

            // Bottom Frosted-Glass Time Scrubber & Calendar Export Bar
            TimeScrubberControlView()
        }
        .background(Color(.systemGroupedBackground))
    }
}
