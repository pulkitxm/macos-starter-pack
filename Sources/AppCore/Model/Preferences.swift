import AppKit

public enum Preferences {
    public static let nameKey = "name"
    public static let packSizeKey = "packSize"
    public static let themeKey = "theme"
    public static let colorfulIconsKey = "colorfulIcons"

    public static func packSize(in defaults: UserDefaults = .standard) -> Int {
        Pack.clampedSize(defaults.object(forKey: packSizeKey) as? Int ?? Pack.defaultSize)
    }
}

public enum Theme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: Self { self }

    public var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    public var appearanceName: NSAppearance.Name? {
        switch self {
        case .system: nil
        case .light: .aqua
        case .dark: .darkAqua
        }
    }
}
