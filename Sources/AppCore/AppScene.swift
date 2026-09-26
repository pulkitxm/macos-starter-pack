import SwiftUI

public struct AppScene: Scene {
    @State private var store = PackStore()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
        .defaultSize(width: 920, height: 620)
        .commands {
            SidebarCommands()
            PackCommands(store: store)
        }

        Settings {
            SettingsView()
        }
    }
}

struct PackCommands: Commands {
    let store: PackStore
    @AppStorage(Preferences.packSizeKey) private var packSize = Pack.defaultSize

    var body: some Commands {
        CommandMenu("Pack") {
            Button("Shuffle Pack") {
                store.shuffle(size: packSize)
            }
            .keyboardShortcut("r")
        }
    }
}
