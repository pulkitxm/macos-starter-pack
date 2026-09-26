import Testing

@testable import AppCore

struct GreetingTests {
    @Test(arguments: [
        (0, "Good evening"),
        (4, "Good evening"),
        (5, "Good morning"),
        (11, "Good morning"),
        (12, "Good afternoon"),
        (16, "Good afternoon"),
        (17, "Good evening"),
        (23, "Good evening"),
    ])
    func salutationFollowsTheHour(hour: Int, expected: String) {
        #expect(Greeting.text(name: "", hour: hour) == expected)
    }

    @Test func includesTheTrimmedName() {
        #expect(Greeting.text(name: "  Ada \n", hour: 9) == "Good morning, Ada")
    }

    @Test func blankNameIsLeftOut() {
        #expect(Greeting.text(name: "   ", hour: 20) == "Good evening")
    }
}
