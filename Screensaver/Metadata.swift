// SpeedS@ver - based on the original by orta therox (2013), MIT.

import Foundation

struct Video {
    let name: String
    let urlString: String
    let console: String
}

struct Console {
    let name: String
    let videos: [Video]
}

struct VideoLibrary {
    let consoles: [Console]

    static func load() -> VideoLibrary {
        guard let url = Bundle(for: GamesScreensaverView.self).url(forResource: "metadata", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return VideoLibrary(consoles: [])
        }

        let consoles: [Console] = raw.compactMap { entry in
            guard let name = entry["console"] as? String,
                  let movies = entry["movies"] as? [[String: String]] else { return nil }
            let videos = movies.compactMap { m -> Video? in
                guard let n = m["name"], let u = m["url"] else { return nil }
                return Video(name: stripConsolePrefix(n, console: name), urlString: u, console: name)
            }
            return Console(name: name, videos: videos)
        }
        return VideoLibrary(consoles: consoles)
    }

    func pickRandom(enabled: Set<String>?) -> Video? {
        let pool = consoles.filter { enabled == nil || enabled!.contains($0.name) }
        return pool.flatMap(\.videos).randomElement()
    }
}

private func stripConsolePrefix(_ title: String, console: String) -> String {
    let prefix = console + " "
    if title.lowercased().hasPrefix(prefix.lowercased()) {
        return String(title.dropFirst(prefix.count))
    }
    return title
}
