import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettings()
            }
            Tab("Appearance", systemImage: "paintpalette") {
                AppearanceSettings()
            }
        }
        .frame(width: 460)
        .appliesTheme()
    }
}

struct GeneralSettings: View {
    @AppStorage(Preferences.nameKey) private var name = ""
    @AppStorage(Preferences.packSizeKey) private var packSize = Pack.defaultSize

    var body: some View {
        Form {
            TextField("Your name", text: $name, prompt: Text("Optional"))
            LabeledContent("Things in the pack") {
                Text(packSize, format: .number)
                    .monospacedDigit()
                Stepper("Things in the pack", value: $packSize, in: Pack.sizes)
                    .labelsHidden()
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct AppearanceSettings: View {
    @AppStorage(Preferences.themeKey) private var theme = Theme.system
    @AppStorage(Preferences.colorfulIconsKey) private var colorfulIcons = true

    var body: some View {
        Form {
            Picker("Theme", selection: $theme) {
                ForEach(Theme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            Toggle("Colorful icons", isOn: $colorfulIcons)
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
    }
}
