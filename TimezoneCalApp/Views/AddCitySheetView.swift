import SwiftUI

/// Searchable sheet to add a city to the active preset group or change the user's primary Home City.
public struct AddCitySheetView: View {
    @EnvironmentObject private var store: TimezoneStore
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var mode: SelectionMode

    public enum SelectionMode: String, CaseIterable, Identifiable {
        case addToGroup = "Add to List"
        case setHomeCity = "Change Home City"

        public var id: String { rawValue }
    }

    public init(initialMode: SelectionMode = .addToGroup) {
        _mode = State(initialValue: initialMode)
    }

    private var filteredCities: [CityTimezone] {
        let base = CityCatalog.search(query: searchText)
        if mode == .setHomeCity && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Keep current home city pinned at the very top when browsing
            var reordered = base.filter { $0.id != store.homeCity.id }
            reordered.insert(store.homeCity, at: 0)
            return reordered
        }
        return base
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Action", selection: $mode) {
                    ForEach(SelectionMode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                List {
                    ForEach(filteredCities) { city in
                        let isAlreadyAdded = store.activeCities.contains(where: { $0.id == city.id })
                        let isCurrentHome = store.homeCity.id == city.id

                        Button {
                            if mode == .setHomeCity {
                                store.homeCity = city
                                store.activeReferenceCityID = city.id
                                dismiss()
                            } else if !isAlreadyAdded {
                                store.addCity(city)
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(city.flagEmoji)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(city.cityName)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.primary)

                                        Text(city.shortCode)
                                            .font(.caption2.weight(.bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(Color(.tertiarySystemFill), in: Capsule())
                                            .foregroundStyle(.secondary)

                                        if isCurrentHome {
                                            Label("HOME", systemImage: "house.fill")
                                                .font(.system(size: 9, weight: .heavy))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.16), in: Capsule())
                                                .foregroundStyle(.blue)
                                        }
                                    }

                                    Text("\(city.countryOrRegion) • \(city.timeZoneIdentifier)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(city.formattedTime(at: store.selectedDate, use24Hour: store.use24HourFormat))
                                        .font(.subheadline.monospacedDigit().weight(.bold))
                                        .foregroundStyle(.primary)

                                    if mode == .setHomeCity && isCurrentHome {
                                        Text("Current Home")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.blue)
                                    } else if mode == .addToGroup && isAlreadyAdded {
                                        Text("Added")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.green)
                                    } else {
                                        Text(city.formattedOffsetBadge(relativeTo: store.homeCity, at: store.selectedDate))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .disabled(mode == .addToGroup && isAlreadyAdded)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search city, country, or code (e.g. TYO, London)")
            .navigationTitle(mode == .setHomeCity ? "Select Home City" : "Add City to \(store.activeGroup.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
