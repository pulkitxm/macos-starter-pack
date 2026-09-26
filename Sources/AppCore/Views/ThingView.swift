import SwiftUI

struct ThingView: View {
    let thing: Thing
    @AppStorage(Preferences.colorfulIconsKey) private var colorfulIcons = true

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: thing.symbol)
                .font(.system(size: 72))
                .foregroundStyle(colorfulIcons ? thing.tint : .secondary)
            Text(thing.name)
                .font(.largeTitle.bold())
            Text(thing.blurb)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(thing.name)
    }
}
