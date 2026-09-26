import SwiftUI

public enum Catalog {
    public static let things: [Thing] = [
        Thing(
            id: "coffee", name: "Fresh Coffee", symbol: "cup.and.saucer.fill", tint: .brown,
            blurb: "Fuel for the first build of the day."),
        Thing(
            id: "duck", name: "Rubber Duck", symbol: "bird.fill", tint: .yellow,
            blurb: "Listens to every bug report without judgement."),
        Thing(
            id: "keyboard", name: "Clicky Keyboard", symbol: "keyboard.fill", tint: .gray,
            blurb: "Loud enough that everyone knows you are shipping."),
        Thing(
            id: "headphones", name: "Headphones", symbol: "headphones", tint: .indigo,
            blurb: "Focus mode, but physical."),
        Thing(
            id: "notebook", name: "Notebook", symbol: "book.closed.fill", tint: .orange,
            blurb: "Where good ideas wait before they become tickets."),
        Thing(
            id: "plant", name: "Desk Plant", symbol: "leaf.fill", tint: .green,
            blurb: "Thrives on sunlight and passing checks."),
        Thing(
            id: "lamp", name: "Warm Lamp", symbol: "lamp.desk.fill", tint: .orange,
            blurb: "Late night releases deserve good lighting."),
        Thing(
            id: "notes", name: "Sticky Notes", symbol: "note.text", tint: .yellow,
            blurb: "A to-do list you can lose in seconds."),
        Thing(
            id: "box", name: "Shipping Box", symbol: "shippingbox.fill", tint: .brown,
            blurb: "Packs the app into a signed disk image."),
        Thing(
            id: "ideas", name: "Fresh Ideas", symbol: "sparkles", tint: .purple,
            blurb: "Freshly generated, never compiled."),
        Thing(
            id: "night", name: "Night Mode", symbol: "moon.stars.fill", tint: .blue,
            blurb: "Dark appearance, darker coffee."),
        Thing(
            id: "playlist", name: "Playlist", symbol: "music.note", tint: .pink,
            blurb: "Four hours of lo-fi on repeat."),
        Thing(
            id: "toolbox", name: "Toolbox", symbol: "hammer.fill", tint: .red,
            blurb: "Everything you need to build, test and ship."),
        Thing(
            id: "break", name: "Break Time", symbol: "gamecontroller.fill", tint: .teal,
            blurb: "One more level while the tests run."),
        Thing(
            id: "confetti", name: "Confetti", symbol: "party.popper.fill", tint: .mint,
            blurb: "Saved for the moment the release goes green."),
    ]

    public static let taglines = [
        "Small, native, and ready to ship.",
        "A sidebar, a home, and settings. The rest is yours.",
        "Tested, signed, and packed for the road.",
        "Everything you need, nothing you will delete later.",
        "Built with the parts macOS already gives you.",
    ]
}
