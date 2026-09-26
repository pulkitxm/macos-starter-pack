import SwiftUI

struct Sidebar: View {
    let things: [Thing]
    @Binding var selection: Destination?
    @AppStorage(Preferences.colorfulIconsKey) private var colorfulIcons = true

    var body: some View {
        List(selection: $selection) {
            Label("Home", systemImage: "house")
                .tag(Destination.home)

            Section("In the Pack") {
                ForEach(things) { thing in
                    Label {
                        Text(thing.name)
                    } icon: {
                        Image(systemName: thing.symbol)
                            .foregroundStyle(colorfulIcons ? thing.tint : .secondary)
                    }
                    .tag(Destination.thing(thing.id))
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        .safeAreaInset(edge: .bottom) {
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
    }
}
