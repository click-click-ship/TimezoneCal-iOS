import SwiftUI

/// Native iOS-styled modal sheet for creating, renaming, reordering, and deleting City Preset Groups.
public struct ManageGroupsSheetView: View {
    @EnvironmentObject private var store: TimezoneStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode

    private enum EditorMode: Identifiable {
        case create
        case edit(CityGroup)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let group): return "edit_\(group.id)"
            }
        }
    }

    @State private var editorMode: EditorMode?

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
                // MARK: Saved Groups (Tap to Switch, Pencil/Swipe to Rename, Edit to Reorder)
                Section {
                    ForEach(store.groups) { group in
                        HStack(spacing: 12) {
                            Image(systemName: group.iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.red, in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(group.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    if store.selectedGroupID == group.id {
                                        Text("Active")
                                            .font(.caption2.weight(.bold))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.15), in: Capsule())
                                            .foregroundStyle(.red)
                                    }
                                }

                                Text("\(group.cities.count) \(group.cities.count == 1 ? "city" : "cities"): \(group.cities.map(\.cityName).joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Obvious 1-tap Rename / Edit Icon button
                            Button {
                                editorMode = .edit(group)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, height: 30)
                                    .background(Color(.tertiarySystemFill), in: Circle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Rename \(group.name)")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard editMode?.wrappedValue != .active else { return }
                            store.selectedGroupID = group.id
                            dismiss()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if store.groups.count > 1 {
                                Button(role: .destructive) {
                                    store.deleteGroup(group)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }

                            Button {
                                editorMode = .edit(group)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                editorMode = .edit(group)
                            } label: {
                                Label("Rename & Icon", systemImage: "pencil")
                            }

                            if store.groups.count > 1 {
                                Divider()
                                Button(role: .destructive) {
                                    store.deleteGroup(group)
                                } label: {
                                    Label("Delete Group", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        guard store.groups.count > offsets.count else { return }
                        for idx in offsets.sorted(by: >) {
                            store.deleteGroup(store.groups[idx])
                        }
                    }
                    .onMove(perform: store.moveGroups)
                } header: {
                    Text("Your Groups")
                } footer: {
                    Text("Tap a group to switch, tap the pencil or swipe left to rename, or tap Edit to reorder.")
                }

                // MARK: Quick "+ New Group" Row (Apple Notes / Reminders style)
                Section {
                    Button {
                        editorMode = .create
                    } label: {
                        Label("New Group", systemImage: "plus.circle.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("City Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        editorMode = .create
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("New Group")

                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(item: $editorMode) { mode in
                GroupEditorSheet(
                    availableIcons: availableIcons,
                    existingGroup: {
                        if case .edit(let group) = mode { return group }
                        return nil
                    }()
                ) { name, icon in
                    switch mode {
                    case .create:
                        store.addGroup(name: name, iconName: icon)
                    case .edit(let group):
                        store.renameGroup(group, to: name, iconName: icon)
                    }
                }
            }
        }
    }
}

/// Shared modal editor for creating or renaming a City Group with an icon.
private struct GroupEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFieldFocused: Bool

    let availableIcons: [String]
    let existingGroup: CityGroup?
    let onSave: (String, String) -> Void

    @State private var nameText: String
    @State private var selectedIcon: String

    init(
        availableIcons: [String],
        existingGroup: CityGroup?,
        onSave: @escaping (String, String) -> Void
    ) {
        self.availableIcons = availableIcons
        self.existingGroup = existingGroup
        self.onSave = onSave
        _nameText = State(initialValue: existingGroup?.name ?? "")
        _selectedIcon = State(initialValue: existingGroup?.iconName ?? "briefcase.fill")
    }

    private var trimmedName: String {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Name") {
                    TextField("e.g. APAC Team, Clients, Family", text: $nameText)
                        .focused($isNameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            saveAndDismiss()
                        }
                }

                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 40, height: 40)
                                        .background(
                                            selectedIcon == icon ? Color.red : Color(.tertiarySystemFill),
                                            in: Circle()
                                        )
                                        .foregroundStyle(
                                            selectedIcon == icon ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(existingGroup == nil ? "New Group" : "Rename Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingGroup == nil ? "Create" : "Save") {
                        saveAndDismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
        .presentationDetents([.medium])
    }

    private func saveAndDismiss() {
        guard !trimmedName.isEmpty else { return }
        onSave(trimmedName, selectedIcon)
        dismiss()
    }
}
