import SwiftUI

struct HomeView: View {
    let store: PackStore
    @Binding var selection: Destination?
    @AppStorage(Preferences.nameKey) private var name = ""
    @AppStorage(Preferences.colorfulIconsKey) private var colorfulIcons = true

    private let columns = [GridItem(.adaptive(minimum: 170), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                VStack(alignment: .leading, spacing: 12) {
                    Text("What's in the pack")
                        .font(.headline)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(store.things) { thing in
                            Button {
                                selection = .thing(thing.id)
                            } label: {
                                ThingTile(thing: thing, colorfulIcons: colorfulIcons)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Home")
    }

    private var header: some View {
        HStack(spacing: 20) {
            Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
                .resizable()
                .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Starter Pack")
                    .font(.largeTitle.bold())
                Text(store.tagline)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var greeting: String {
        Greeting.text(name: name, hour: Calendar.current.component(.hour, from: .now))
    }
}

struct ThingTile: View {
    let thing: Thing
    let colorfulIcons: Bool

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: thing.symbol)
                    .font(.title)
                    .foregroundStyle(colorfulIcons ? thing.tint : .secondary)
                    .frame(height: 34)
                Text(thing.name)
                    .font(.headline)
                Text(thing.blurb)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .contentShape(.rect)
    }
}
