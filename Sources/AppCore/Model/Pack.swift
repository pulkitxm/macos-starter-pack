public enum Pack {
    public static let sizes = 3...8
    public static let defaultSize = 5

    public static func clampedSize(_ size: Int) -> Int {
        min(max(size, sizes.lowerBound), sizes.upperBound)
    }

    public static func random(
        size: Int,
        from things: [Thing] = Catalog.things,
        using generator: inout some RandomNumberGenerator
    ) -> [Thing] {
        Array(things.shuffled(using: &generator).prefix(clampedSize(size)))
    }
}
