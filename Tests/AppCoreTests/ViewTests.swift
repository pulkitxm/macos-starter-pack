import AppKit
import SwiftUI
import Testing

@testable import AppCore

@MainActor
struct ViewTests {
    private func render(_ view: some View, size: CGSize) -> NSHostingView<AnyView> {
        let host = NSHostingView(rootView: AnyView(view))
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        return host
    }

    @Test func rootViewLaysOut() {
        let host = render(
            RootView(store: PackStore(size: 5)), size: CGSize(width: 920, height: 620))
        #expect(host.fittingSize.width > 0)
        #expect(host.fittingSize.height > 0)
    }

    @Test func homeViewLaysOut() {
        let home = HomeView(store: PackStore(size: 8), selection: .constant(.home))
        let host = render(home, size: CGSize(width: 700, height: 600))
        #expect(host.fittingSize.height > 0)
    }

    @Test(arguments: Catalog.things)
    func thingViewLaysOut(thing: Thing) {
        let host = render(ThingView(thing: thing), size: CGSize(width: 600, height: 400))
        #expect(host.fittingSize.width > 0)
    }

    @Test func settingsLayOut() {
        let host = render(SettingsView(), size: CGSize(width: 460, height: 240))
        #expect(host.fittingSize.width == 460)
    }
}
