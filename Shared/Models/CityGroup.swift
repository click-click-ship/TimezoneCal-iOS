import Foundation

/// A named preset collection of target cities (e.g., "Work Team", "Family & Friends", "Travel").
public struct CityGroup: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var iconName: String
    public var cities: [CityTimezone]

    public init(
        id: String = UUID().uuidString,
        name: String,
        iconName: String = "globe.americas.fill",
        cities: [CityTimezone]
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.cities = cities
    }

    /// Default starter groups pre-populated on first launch.
    public static var defaultGroups: [CityGroup] {
        [
            CityGroup(
                id: "group_work",
                name: "Work Team",
                iconName: "briefcase.fill",
                cities: [
                    CityCatalog.newYork,
                    CityCatalog.london,
                    CityCatalog.berlin,
                    CityCatalog.tokyo
                ]
            ),
            CityGroup(
                id: "group_family",
                name: "Family",
                iconName: "house.fill",
                cities: [
                    CityCatalog.chicago,
                    CityCatalog.toronto,
                    CityCatalog.sydney
                ]
            ),
            CityGroup(
                id: "group_travel",
                name: "Travel & APAC",
                iconName: "airplane",
                cities: [
                    CityCatalog.paris,
                    CityCatalog.dubai,
                    CityCatalog.singapore,
                    CityCatalog.seoul
                ]
            )
        ]
    }
}
