import Foundation

/// Built-in curated catalog of major world cities plus automatic fallback search across all IANA TimeZone identifiers.
public enum CityCatalog {

    // MARK: - Featured Cities Used in Default Presets & Widgets

    public static let sanFrancisco = CityTimezone(
        id: "san_francisco_us",
        cityName: "San Francisco",
        countryOrRegion: "United States",
        countryCode: "US",
        timeZoneIdentifier: "America/Los_Angeles",
        shortCode: "SFO"
    )

    public static let newYork = CityTimezone(
        id: "new_york_us",
        cityName: "New York",
        countryOrRegion: "United States",
        countryCode: "US",
        timeZoneIdentifier: "America/New_York",
        shortCode: "NYC"
    )

    public static let chicago = CityTimezone(
        id: "chicago_us",
        cityName: "Chicago",
        countryOrRegion: "United States",
        countryCode: "US",
        timeZoneIdentifier: "America/Chicago",
        shortCode: "CHI"
    )

    public static let toronto = CityTimezone(
        id: "toronto_ca",
        cityName: "Toronto",
        countryOrRegion: "Canada",
        countryCode: "CA",
        timeZoneIdentifier: "America/Toronto",
        shortCode: "YYZ"
    )

    public static let london = CityTimezone(
        id: "london_gb",
        cityName: "London",
        countryOrRegion: "United Kingdom",
        countryCode: "GB",
        timeZoneIdentifier: "Europe/London",
        shortCode: "LON"
    )

    public static let paris = CityTimezone(
        id: "paris_fr",
        cityName: "Paris",
        countryOrRegion: "France",
        countryCode: "FR",
        timeZoneIdentifier: "Europe/Paris",
        shortCode: "PAR"
    )

    public static let berlin = CityTimezone(
        id: "berlin_de",
        cityName: "Berlin",
        countryOrRegion: "Germany",
        countryCode: "DE",
        timeZoneIdentifier: "Europe/Berlin",
        shortCode: "BER"
    )

    public static let dubai = CityTimezone(
        id: "dubai_ae",
        cityName: "Dubai",
        countryOrRegion: "United Arab Emirates",
        countryCode: "AE",
        timeZoneIdentifier: "Asia/Dubai",
        shortCode: "DXB"
    )

    public static let singapore = CityTimezone(
        id: "singapore_sg",
        cityName: "Singapore",
        countryOrRegion: "Singapore",
        countryCode: "SG",
        timeZoneIdentifier: "Asia/Singapore",
        shortCode: "SIN"
    )

    public static let tokyo = CityTimezone(
        id: "tokyo_jp",
        cityName: "Tokyo",
        countryOrRegion: "Japan",
        countryCode: "JP",
        timeZoneIdentifier: "Asia/Tokyo",
        shortCode: "TYO"
    )

    public static let seoul = CityTimezone(
        id: "seoul_kr",
        cityName: "Seoul",
        countryOrRegion: "South Korea",
        countryCode: "KR",
        timeZoneIdentifier: "Asia/Seoul",
        shortCode: "SEL"
    )

    public static let sydney = CityTimezone(
        id: "sydney_au",
        cityName: "Sydney",
        countryOrRegion: "Australia",
        countryCode: "AU",
        timeZoneIdentifier: "Australia/Sydney",
        shortCode: "SYD"
    )

    // MARK: - Comprehensive Curated Global Directory

    public static let curatedCities: [CityTimezone] = [
        // North America
        sanFrancisco,
        CityTimezone(cityName: "Los Angeles", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/Los_Angeles", shortCode: "LAX"),
        CityTimezone(cityName: "Seattle", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/Los_Angeles", shortCode: "SEA"),
        CityTimezone(cityName: "Vancouver", countryOrRegion: "Canada", countryCode: "CA", timeZoneIdentifier: "America/Vancouver", shortCode: "YVR"),
        CityTimezone(cityName: "Phoenix", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/Phoenix", shortCode: "PHX"),
        CityTimezone(cityName: "Denver", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/Denver", shortCode: "DEN"),
        chicago,
        CityTimezone(cityName: "Austin", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/Chicago", shortCode: "AUS"),
        CityTimezone(cityName: "Dallas", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/Chicago", shortCode: "DFW"),
        CityTimezone(cityName: "Mexico City", countryOrRegion: "Mexico", countryCode: "MX", timeZoneIdentifier: "America/Mexico_City", shortCode: "MEX"),
        newYork,
        CityTimezone(cityName: "Boston", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/New_York", shortCode: "BOS"),
        CityTimezone(cityName: "Miami", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/New_York", shortCode: "MIA"),
        CityTimezone(cityName: "Atlanta", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/New_York", shortCode: "ATL"),
        toronto,
        CityTimezone(cityName: "Montreal", countryOrRegion: "Canada", countryCode: "CA", timeZoneIdentifier: "America/Toronto", shortCode: "YUL"),
        CityTimezone(cityName: "Honolulu", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "Pacific/Honolulu", shortCode: "HNL"),
        CityTimezone(cityName: "Anchorage", countryOrRegion: "United States", countryCode: "US", timeZoneIdentifier: "America/Anchorage", shortCode: "ANC"),

        // Latin America
        CityTimezone(cityName: "São Paulo", countryOrRegion: "Brazil", countryCode: "BR", timeZoneIdentifier: "America/Sao_Paulo", shortCode: "GRU"),
        CityTimezone(cityName: "Buenos Aires", countryOrRegion: "Argentina", countryCode: "AR", timeZoneIdentifier: "America/Argentina/Buenos_Aires", shortCode: "EZE"),
        CityTimezone(cityName: "Santiago", countryOrRegion: "Chile", countryCode: "CL", timeZoneIdentifier: "America/Santiago", shortCode: "SCL"),
        CityTimezone(cityName: "Bogotá", countryOrRegion: "Colombia", countryCode: "CO", timeZoneIdentifier: "America/Bogota", shortCode: "BOG"),
        CityTimezone(cityName: "Lima", countryOrRegion: "Peru", countryCode: "PE", timeZoneIdentifier: "America/Lima", shortCode: "LIM"),

        // Europe
        london,
        CityTimezone(cityName: "Dublin", countryOrRegion: "Ireland", countryCode: "IE", timeZoneIdentifier: "Europe/Dublin", shortCode: "DUB"),
        CityTimezone(cityName: "Lisbon", countryOrRegion: "Portugal", countryCode: "PT", timeZoneIdentifier: "Europe/Lisbon", shortCode: "LIS"),
        paris,
        berlin,
        CityTimezone(cityName: "Amsterdam", countryOrRegion: "Netherlands", countryCode: "NL", timeZoneIdentifier: "Europe/Amsterdam", shortCode: "AMS"),
        CityTimezone(cityName: "Madrid", countryOrRegion: "Spain", countryCode: "ES", timeZoneIdentifier: "Europe/Madrid", shortCode: "MAD"),
        CityTimezone(cityName: "Barcelona", countryOrRegion: "Spain", countryCode: "ES", timeZoneIdentifier: "Europe/Madrid", shortCode: "BCN"),
        CityTimezone(cityName: "Rome", countryOrRegion: "Italy", countryCode: "IT", timeZoneIdentifier: "Europe/Rome", shortCode: "ROM"),
        CityTimezone(cityName: "Zurich", countryOrRegion: "Switzerland", countryCode: "CH", timeZoneIdentifier: "Europe/Zurich", shortCode: "ZRH"),
        CityTimezone(cityName: "Vienna", countryOrRegion: "Austria", countryCode: "AT", timeZoneIdentifier: "Europe/Vienna", shortCode: "VIE"),
        CityTimezone(cityName: "Stockholm", countryOrRegion: "Sweden", countryCode: "SE", timeZoneIdentifier: "Europe/Stockholm", shortCode: "ARN"),
        CityTimezone(cityName: "Copenhagen", countryOrRegion: "Denmark", countryCode: "DK", timeZoneIdentifier: "Europe/Copenhagen", shortCode: "CPH"),
        CityTimezone(cityName: "Oslo", countryOrRegion: "Norway", countryCode: "NO", timeZoneIdentifier: "Europe/Oslo", shortCode: "OSL"),
        CityTimezone(cityName: "Warsaw", countryOrRegion: "Poland", countryCode: "PL", timeZoneIdentifier: "Europe/Warsaw", shortCode: "WAW"),
        CityTimezone(cityName: "Prague", countryOrRegion: "Czechia", countryCode: "CZ", timeZoneIdentifier: "Europe/Prague", shortCode: "PRG"),
        CityTimezone(cityName: "Athens", countryOrRegion: "Greece", countryCode: "GR", timeZoneIdentifier: "Europe/Athens", shortCode: "ATH"),
        CityTimezone(cityName: "Helsinki", countryOrRegion: "Finland", countryCode: "FI", timeZoneIdentifier: "Europe/Helsinki", shortCode: "HEL"),
        CityTimezone(cityName: "Istanbul", countryOrRegion: "Turkey", countryCode: "TR", timeZoneIdentifier: "Europe/Istanbul", shortCode: "IST"),

        // Middle East & Africa
        dubai,
        CityTimezone(cityName: "Tel Aviv", countryOrRegion: "Israel", countryCode: "IL", timeZoneIdentifier: "Asia/Jerusalem", shortCode: "TLV"),
        CityTimezone(cityName: "Riyadh", countryOrRegion: "Saudi Arabia", countryCode: "SA", timeZoneIdentifier: "Asia/Riyadh", shortCode: "RUH"),
        CityTimezone(cityName: "Doha", countryOrRegion: "Qatar", countryCode: "QA", timeZoneIdentifier: "Asia/Qatar", shortCode: "DOH"),
        CityTimezone(cityName: "Cairo", countryOrRegion: "Egypt", countryCode: "EG", timeZoneIdentifier: "Africa/Cairo", shortCode: "CAI"),
        CityTimezone(cityName: "Lagos", countryOrRegion: "Nigeria", countryCode: "NG", timeZoneIdentifier: "Africa/Lagos", shortCode: "LOS"),
        CityTimezone(cityName: "Nairobi", countryOrRegion: "Kenya", countryCode: "KE", timeZoneIdentifier: "Africa/Nairobi", shortCode: "NBO"),
        CityTimezone(cityName: "Johannesburg", countryOrRegion: "South Africa", countryCode: "ZA", timeZoneIdentifier: "Africa/Johannesburg", shortCode: "JNB"),

        // Asia & Pacific
        CityTimezone(cityName: "Mumbai", countryOrRegion: "India", countryCode: "IN", timeZoneIdentifier: "Asia/Kolkata", shortCode: "BOM"),
        CityTimezone(cityName: "Bengaluru", countryOrRegion: "India", countryCode: "IN", timeZoneIdentifier: "Asia/Kolkata", shortCode: "BLR"),
        CityTimezone(cityName: "New Delhi", countryOrRegion: "India", countryCode: "IN", timeZoneIdentifier: "Asia/Kolkata", shortCode: "DEL"),
        CityTimezone(cityName: "Kathmandu", countryOrRegion: "Nepal", countryCode: "NP", timeZoneIdentifier: "Asia/Kathmandu", shortCode: "KTM"),
        CityTimezone(cityName: "Bangkok", countryOrRegion: "Thailand", countryCode: "TH", timeZoneIdentifier: "Asia/Bangkok", shortCode: "BKK"),
        CityTimezone(cityName: "Jakarta", countryOrRegion: "Indonesia", countryCode: "ID", timeZoneIdentifier: "Asia/Jakarta", shortCode: "CGK"),
        CityTimezone(cityName: "Ho Chi Minh City", countryOrRegion: "Vietnam", countryCode: "VN", timeZoneIdentifier: "Asia/Ho_Chi_Minh", shortCode: "SGN"),
        singapore,
        CityTimezone(cityName: "Kuala Lumpur", countryOrRegion: "Malaysia", countryCode: "MY", timeZoneIdentifier: "Asia/Kuala_Lumpur", shortCode: "KUL"),
        CityTimezone(cityName: "Manila", countryOrRegion: "Philippines", countryCode: "PH", timeZoneIdentifier: "Asia/Manila", shortCode: "MNL"),
        CityTimezone(cityName: "Hong Kong", countryOrRegion: "Hong Kong", countryCode: "HK", timeZoneIdentifier: "Asia/Hong_Kong", shortCode: "HKG"),
        CityTimezone(cityName: "Taipei", countryOrRegion: "Taiwan", countryCode: "TW", timeZoneIdentifier: "Asia/Taipei", shortCode: "TPE"),
        CityTimezone(cityName: "Shanghai", countryOrRegion: "China", countryCode: "CN", timeZoneIdentifier: "Asia/Shanghai", shortCode: "SHA"),
        CityTimezone(cityName: "Beijing", countryOrRegion: "China", countryCode: "CN", timeZoneIdentifier: "Asia/Shanghai", shortCode: "PEK"),
        seoul,
        tokyo,
        CityTimezone(cityName: "Perth", countryOrRegion: "Australia", countryCode: "AU", timeZoneIdentifier: "Australia/Perth", shortCode: "PER"),
        CityTimezone(cityName: "Adelaide", countryOrRegion: "Australia", countryCode: "AU", timeZoneIdentifier: "Australia/Adelaide", shortCode: "ADL"),
        CityTimezone(cityName: "Melbourne", countryOrRegion: "Australia", countryCode: "AU", timeZoneIdentifier: "Australia/Melbourne", shortCode: "MEL"),
        sydney,
        CityTimezone(cityName: "Brisbane", countryOrRegion: "Australia", countryCode: "AU", timeZoneIdentifier: "Australia/Brisbane", shortCode: "BNE"),
        CityTimezone(cityName: "Auckland", countryOrRegion: "New Zealand", countryCode: "NZ", timeZoneIdentifier: "Pacific/Auckland", shortCode: "AKL")
    ]

    /// Detects the user's current device timezone and returns a matching `CityTimezone` as their initial Home City.
    public static func detectDeviceHomeCity() -> CityTimezone {
        let localTZ = TimeZone.current
        if let match = curatedCities.first(where: { $0.timeZoneIdentifier == localTZ.identifier }) {
            return match
        }
        let parts = localTZ.identifier.split(separator: "/")
        let cityPart = parts.last.map { String($0).replacingOccurrences(of: "_", with: " ") } ?? "Home"
        let regionPart = parts.first.map { String($0) } ?? "Local"
        return CityTimezone(
            id: "device_home_\(localTZ.identifier)",
            cityName: cityPart,
            countryOrRegion: regionPart,
            countryCode: Locale.current.region?.identifier ?? "US",
            timeZoneIdentifier: localTZ.identifier
        )
    }

    /// Searches both the curated city directory and all system IANA timezone identifiers.
    public static func search(query: String) -> [CityTimezone] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return curatedCities
        }
        let lower = trimmed.lowercased()

        // 1. Filter curated matches first
        var results = curatedCities.filter {
            $0.cityName.lowercased().contains(lower) ||
            $0.countryOrRegion.lowercased().contains(lower) ||
            $0.shortCode.lowercased().contains(lower) ||
            $0.timeZoneIdentifier.lowercased().contains(lower)
        }

        let existingIDs = Set(results.map { $0.timeZoneIdentifier })

        // 2. Supplement with any system IANA timezone not already represented
        let ianaMatches = TimeZone.knownTimeZoneIdentifiers
            .filter { $0.lowercased().contains(lower) && !existingIDs.contains($0) }
            .prefix(20)
            .map { identifier -> CityTimezone in
                let parts = identifier.split(separator: "/")
                let city = parts.last.map { String($0).replacingOccurrences(of: "_", with: " ") } ?? identifier
                let region = parts.first.map { String($0) } ?? "Global"
                return CityTimezone(
                    cityName: city,
                    countryOrRegion: region,
                    countryCode: "",
                    timeZoneIdentifier: identifier
                )
            }

        results.append(contentsOf: ianaMatches)
        return results
    }
}
