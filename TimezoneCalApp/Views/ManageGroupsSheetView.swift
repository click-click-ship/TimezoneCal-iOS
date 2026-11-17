import SwiftUI

/// Modal sheet allowing users to create custom City Preset Groups (e.g. "Work Team", "Family", "Clients")
/// and reorder or remove existing cities.
public struct ManageGroupsSheetView: View {
    @EnvironmentObject private var store: TimezoneStore
    @Environment(\.dismiss) private var dismiss

    @State private var newGroupName: String = ""
    @State private var selectedIcon: String = "briefcase.fill"

    private let availableIcons = [
        "briefcase.fill",
        "house.fill",
        "airplane",
        "person.3.fill",
        "building.2.fill",
        "globe.americas.fill",
        "star.fill"
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // MARK: Create New Preset Group
                Section("Create New City Group") {
                    TextField("Group Name (e.g. APAC Team, Clients)", text: $newGroupName)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 36, height: 36)
                                        .background(
                                            selectedIcon == icon ? Color.red : Color(.tertiarySystemFill),
                                            in: Circle()
                                        )
                                        .foregroundStyle(selectedIcon == icon ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        store.addGroup(name: newGroupName, iconName: selectedIcon)
                        newGroupName = ""
                    } label: {
                        Label("Create Preset Group", systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                    .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                // MARK: Existing Preset Groups
                Section("Saved Preset Groups") {
                    ForEach(store.groups) { group in
                        HStack {
                            Image(systemName: group.iconName)
                                .foregroundStyle(.red)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name)
                                    .font(.body.weight(.semibold))
                                Text("\(group.cities.count) cities: \(group.cities.map(\.cityName).joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if store.selectedGroupID == group.id {
                                Text("Active")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.red.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.red)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            store.selectedGroupID = group.id
                        }
                        .swipeActions(edge: .trailing) {
                            if store.groups.count > 1 {
                                Button(role: .destructive) {
                                    store.deleteGroup(group)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("City Groups & Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
