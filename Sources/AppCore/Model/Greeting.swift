import Foundation

public enum Greeting {
    public static func text(name: String, hour: Int) -> String {
        let salutation =
            switch hour {
            case 5..<12: "Good morning"
            case 12..<17: "Good afternoon"
            default: "Good evening"
            }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? salutation : "\(salutation), \(trimmedName)"
    }
}
