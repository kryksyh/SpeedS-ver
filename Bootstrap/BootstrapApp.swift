// SpeedS@ver - based on the original by orta therox (2013), MIT.
// Tiny dev host so we can iterate without installing the .saver bundle.

import SwiftUI
import AppKit

@main
struct BootstrapApp: App {
    @StateObject private var hub = SaverHub()

    var body: some Scene {
        WindowGroup("SpeedS@ver") {
            SaverHost(hub: hub)
                .frame(minWidth: 960, minHeight: 540)
                .background(Color.black)
        }
        .commands {
            CommandMenu("Saver") {
                Button("Show Settings…") { hub.showSettings() }
                    .keyboardShortcut(",", modifiers: [.command])
                Button("Skip Video") { hub.skip() }
                    .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}

final class SaverHub: ObservableObject {
    var view: GamesScreensaverView?

    func showSettings() {
        guard let view, let win = view.window, let sheet = view.configureSheet else { return }
        win.beginSheet(sheet, completionHandler: nil)
    }

    func skip() {
        view?.stopAnimation()
        view?.startAnimation()
    }
}

struct SaverHost: NSViewRepresentable {
    let hub: SaverHub

    func makeNSView(context: Context) -> GamesScreensaverView {
        if let existing = hub.view { return existing }
        let v = GamesScreensaverView(frame: NSRect(x: 0, y: 0, width: 960, height: 540), isPreview: false)!
        hub.view = v
        DispatchQueue.main.async { v.startAnimation() }
        return v
    }

    func updateNSView(_ v: GamesScreensaverView, context: Context) {}
}
