import Testing

@testable import AppCore

struct PackTests {
    @Test(arguments: [(-4, 3), (0, 3), (3, 3), (5, 5), (8, 8), (40, 8)])
    func sizeIsClampedToTheSupportedRange(requested: Int, expected: Int) {
        var generator = SeededGenerator(seed: 1)
        #expect(Pack.random(size: requested, using: &generator).count == expected)
    }

    @Test func neverRepeatsAThing() {
        var generator = SeededGenerator(seed: 7)
        let pack = Pack.random(size: Pack.sizes.upperBound, using: &generator)
        #expect(Set(pack.map(\.id)).count == pack.count)
    }

    @Test func sameSeedGivesTheSamePack() {
        var first = SeededGenerator(seed: 42)
        var second = SeededGenerator(seed: 42)
        #expect(Pack.random(size: 5, using: &first) == Pack.random(size: 5, using: &second))
    }

    @Test func differentSeedsGiveDifferentPacks() {
        var first = SeededGenerator(seed: 1)
        var second = SeededGenerator(seed: 2)
        #expect(Pack.random(size: 5, using: &first) != Pack.random(size: 5, using: &second))
    }

    @Test func drawsOnlyFromTheGivenThings() {
        var generator = SeededGenerator(seed: 3)
        let source = Array(Catalog.things.prefix(4))
        let pack = Pack.random(size: 8, from: source, using: &generator)
        #expect(Set(pack) == Set(source))
    }
}
