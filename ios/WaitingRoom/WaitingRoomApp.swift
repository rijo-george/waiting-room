import SwiftUI

@main
struct WaitingRoomApp: App {
    @StateObject private var store = WaitingRoomStore()
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(theme)
        }
    }
}
