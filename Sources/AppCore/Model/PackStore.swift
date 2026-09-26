import Observation

@MainActor
@Observable
public final class PackStore {
    public private(set) var things: [Thing]
    public private(set) var tagline: String

    public init(size: Int = Preferences.packSize()) {
        var generator = SystemRandomNumberGenerator()
        things = Pack.random(size: size, using: &generator)
        tagline = Catalog.taglines.randomElement(using: &generator) ?? ""
    }

    public func shuffle(size: Int) {
        var generator = SystemRandomNumberGenerator()
        shuffle(size: size, using: &generator)
    }

    public func shuffle(size: Int, using generator: inout some RandomNumberGenerator) {
        things = Pack.random(size: size, using: &generator)
        let otherTaglines = Catalog.taglines.filter { $0 != tagline }
        tagline = otherTaglines.randomElement(using: &generator) ?? tagline
    }

    public func thing(id: Thing.ID) -> Thing? {
        things.first { $0.id == id }
    }
}
