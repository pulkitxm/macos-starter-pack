import Testing

@testable import AppCore

@MainActor
struct PackStoreTests {
    @Test func startsWithTheRequestedSize() {
        #expect(PackStore(size: 6).things.count == 6)
    }

    @Test func shuffleResizesThePack() {
        let store = PackStore(size: 3)
        var generator = SeededGenerator(seed: 9)
        store.shuffle(size: 8, using: &generator)
        #expect(store.things.count == 8)
    }

    @Test func shuffleAlwaysChangesTheTagline() {
        let store = PackStore(size: 5)
        var generator = SeededGenerator(seed: 11)
        for _ in 0..<20 {
            let previous = store.tagline
            store.shuffle(size: 5, using: &generator)
            #expect(store.tagline != previous)
            #expect(Catalog.taglines.contains(store.tagline))
        }
    }

    @Test func findsThingsInThePackOnly() throws {
        let store = PackStore(size: 5)
        let packed = try #require(store.things.first)
        let unpacked = try #require(Catalog.things.first { !store.things.contains($0) })
        #expect(store.thing(id: packed.id) == packed)
        #expect(store.thing(id: unpacked.id) == nil)
    }
}
