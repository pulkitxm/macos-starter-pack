import SwiftUI

enum Destination: Hashable {
    case home
    case thing(Thing.ID)
}

struct RootView: View {
    let store: PackStore
    @State private var selection: Destination? = .home
    @AppStorage(Preferences.packSizeKey) private var packSize = Pack.defaultSize

    var body: some View {
        NavigationSplitView {
            Sidebar(things: store.things, selection: $selection)
        } detail: {
            switch selection {
            case .thing(let id):
                if let thing = store.thing(id: id) {
                    ThingView(thing: thing)
                }
            case .home, nil:
                HomeView(store: store, selection: $selection)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Shuffle", systemImage: "shuffle") {
                    store.shuffle(size: packSize)
                }
                .help("Shuffle the pack")
            }
        }
        .onChange(of: packSize) {
            store.shuffle(size: packSize)
        }
        .onChange(of: store.things) {
            if case .thing(let id) = selection, store.thing(id: id) == nil {
                selection = .home
            }
        }
        .appliesTheme()
    }
}

struct ThemeModifier: ViewModifier {
    @AppStorage(Preferences.themeKey) private var theme = Theme.system

    func body(content: Content) -> some View {
        content.onChange(of: theme, initial: true) {
            NSApplication.shared.appearance = theme.appearanceName.flatMap(
                NSAppearance.init(named:))
        }
    }
}

extension View {
    func appliesTheme() -> some View {
        modifier(ThemeModifier())
    }
}
