// SpeedS@ver - based on the original by orta therox (2013), MIT.

import Foundation
import ScreenSaver

private let muteKey = "Mute"
private let consolesKey = "EnabledConsoles"
private let osdKey = "OSD"
private let osdTitleKey = "OSDTitle"
private let osdConsoleKey = "OSDConsole"
private let osdProgressKey = "OSDProgress"
private let osdTimeKey = "OSDTime"
private let osdSizeKey = "OSDSize"

final class SaverDefaults {
    private let store: ScreenSaverDefaults

    init(bundleID: String = "io.github.orta.SpeedS") {
        let s = ScreenSaverDefaults(forModuleWithName: bundleID)!
        s.register(defaults: [
            muteKey: true,
            osdKey: true,
            osdTitleKey: true,
            osdConsoleKey: true,
            osdProgressKey: true,
            osdTimeKey: false,
            osdSizeKey: OSDSize.medium.rawValue,
        ])
        self.store = s
    }

    var muted: Bool {
        get { store.bool(forKey: muteKey) }
        set { store.set(newValue, forKey: muteKey); store.synchronize() }
    }

    var osd: OSDFlags {
        get {
            let raw = store.string(forKey: osdSizeKey) ?? OSDSize.medium.rawValue
            return OSDFlags(
                enabled: store.bool(forKey: osdKey),
                title: store.bool(forKey: osdTitleKey),
                console: store.bool(forKey: osdConsoleKey),
                progress: store.bool(forKey: osdProgressKey),
                time: store.bool(forKey: osdTimeKey),
                size: OSDSize(rawValue: raw) ?? .medium
            )
        }
        set {
            store.set(newValue.enabled, forKey: osdKey)
            store.set(newValue.title, forKey: osdTitleKey)
            store.set(newValue.console, forKey: osdConsoleKey)
            store.set(newValue.progress, forKey: osdProgressKey)
            store.set(newValue.time, forKey: osdTimeKey)
            store.set(newValue.size.rawValue, forKey: osdSizeKey)
            store.synchronize()
        }
    }

    /// nil = "all consoles enabled"
    var enabledConsoles: Set<String>? {
        get {
            guard let arr = store.array(forKey: consolesKey) as? [String] else { return nil }
            return Set(arr)
        }
        set {
            if let v = newValue {
                store.set(Array(v), forKey: consolesKey)
            } else {
                store.removeObject(forKey: consolesKey)
            }
            store.synchronize()
        }
    }
}
