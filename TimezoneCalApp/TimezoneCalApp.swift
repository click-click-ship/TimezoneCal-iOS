import SwiftUI

@main
struct TimezoneCalApp: App {
    @StateObject private var store = TimezoneStore.shared

    var body: some Scene {
        WindowGroup {
            MainCalendarConverterView()
                .environmentObject(store)
                .preferredColorScheme(store.appearanceMode.colorScheme)
        }
    }
}
