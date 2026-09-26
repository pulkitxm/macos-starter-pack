import SwiftUI

public struct Thing: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let symbol: String
    public let tint: Color
    public let blurb: String
}
