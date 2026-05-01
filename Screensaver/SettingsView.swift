// SpeedS@ver - based on the original by orta therox (2013), MIT.

import SwiftUI
import AppKit

struct SettingsView: View {
    let consoles: [Console]
    @State var muted: Bool
    @State var osd: OSDFlags
    @State var enabled: Set<String>
    let onDone: () -> Void
    let persist: (Bool, OSDFlags, Set<String>?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Audio") {
                    Toggle("Mute", isOn: $muted)
                        .onChange(of: muted) { _ in save() }
                }

                Section("Overlay") {
                    Toggle("Show on-screen display", isOn: $osd.enabled)

                    if osd.enabled {
                        Picker("Text size", selection: $osd.size) {
                            ForEach(OSDSize.allCases, id: \.self) { Text($0.label).tag($0) }
                        }
                        Toggle("Run title", isOn: $osd.title)
                        Toggle("Platform badge", isOn: $osd.console)
                        Toggle("Progress bar", isOn: $osd.progress)
                        Toggle("Elapsed time", isOn: $osd.time)
                    }
                }
                .onChange(of: osd) { _ in save() }

                Section {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 4) {
                        ForEach(consoles, id: \.name) { c in
                            Toggle(isOn: binding(for: c.name)) {
                                HStack {
                                    Text(c.name)
                                    Spacer()
                                    Text("\(c.videos.count)")
                                        .foregroundStyle(.tertiary)
                                        .monospacedDigit()
                                        .font(.caption)
                                }
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Text("Consoles")
                        Spacer()
                        Text("\(enabled.count) / \(consoles.count) · \(enabledVideoCount) runs")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Button("All") {
                            enabled = Set(consoles.map(\.name))
                            save()
                        }
                        Button("None") {
                            enabled = []
                            save()
                        }
                    }
                    .font(.callout)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Link("Originally by orta therox, 2013", destination: URL(string: "https://github.com/orta/SpeedS-ver")!)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done") { onDone() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 460, height: 600)
    }

    private var enabledVideoCount: Int {
        consoles.filter { enabled.contains($0.name) }.reduce(0) { $0 + $1.videos.count }
    }

    private func binding(for console: String) -> Binding<Bool> {
        Binding(
            get: { enabled.contains(console) },
            set: { isOn in
                if isOn { enabled.insert(console) } else { enabled.remove(console) }
                save()
            }
        )
    }

    private func save() {
        let allOn = enabled.count == consoles.count
        persist(muted, osd, allOn ? nil : enabled)
    }
}

enum SettingsWindow {
    static func make(library: VideoLibrary, defaults: SaverDefaults, onDone: @escaping () -> Void) -> NSWindow {
        let allNames = Set(library.consoles.map(\.name))
        let initial = defaults.enabledConsoles ?? allNames

        let view = SettingsView(
            consoles: library.consoles,
            muted: defaults.muted,
            osd: defaults.osd,
            enabled: initial,
            onDone: onDone,
            persist: { muted, osd, set in
                defaults.muted = muted
                defaults.osd = osd
                defaults.enabledConsoles = set
            }
        )

        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 460, height: 600)

        let w = NSWindow(
            contentRect: host.frame,
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        w.contentView = host
        w.title = "SpeedS@ver"
        return w
    }
}
