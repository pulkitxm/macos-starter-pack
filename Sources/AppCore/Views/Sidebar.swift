import SwiftUI

struct Sidebar: View {
    let things: [Thing]
    @Binding var selection: Destination?

    var body: some View {
        List(selection: $selection) {
            Label("Home", systemImage: "house")
                .tag(Destination.home)

            Section("In the Pack") {
                ForEach(things) { thing in
                    Label(thing.name, systemImage: thing.symbol)
                        .tag(Destination.thing(thing.id))
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 210)
    }
}
