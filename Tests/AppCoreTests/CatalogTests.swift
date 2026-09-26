import AppKit
import Testing

@testable import AppCore

struct CatalogTests {
    @Test func identifiersAreUnique() {
        let identifiers = Catalog.things.map(\.id)
        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test func holdsEnoughThingsForTheLargestPack() {
        #expect(Catalog.things.count >= Pack.sizes.upperBound)
    }

    @Test(arguments: Catalog.things)
    func everySymbolExists(thing: Thing) {
        #expect(NSImage(systemSymbolName: thing.symbol, accessibilityDescription: nil) != nil)
    }

    @Test(arguments: Catalog.things)
    func everyThingIsDescribed(thing: Thing) {
        #expect(!thing.name.isEmpty)
        #expect(!thing.blurb.isEmpty)
    }

    @Test func taglinesAreDistinct() {
        #expect(Catalog.taglines.count > 1)
        #expect(Set(Catalog.taglines).count == Catalog.taglines.count)
    }
}
