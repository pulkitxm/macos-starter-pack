import AppKit
import Foundation
import Testing

@testable import AppCore

struct PreferencesTests {
    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let suite = "starter.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        body(defaults)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func packSizeDefaultsWhenUnset() {
        withDefaults { defaults in
            #expect(Preferences.packSize(in: defaults) == Pack.defaultSize)
        }
    }

    @Test(arguments: [(2, 3), (6, 6), (99, 8)])
    func packSizeReadsAndClampsTheStoredValue(stored: Int, expected: Int) {
        withDefaults { defaults in
            defaults.set(stored, forKey: Preferences.packSizeKey)
            #expect(Preferences.packSize(in: defaults) == expected)
        }
    }

    @Test func themesMapToAppearances() {
        #expect(Theme.system.appearanceName == nil)
        #expect(Theme.light.appearanceName == .aqua)
        #expect(Theme.dark.appearanceName == .darkAqua)
    }

    @Test func themesRoundTripThroughStorage() {
        for theme in Theme.allCases {
            #expect(Theme(rawValue: theme.rawValue) == theme)
        }
    }
}
