// SpeedS@ver - based on the original by orta therox (2013), MIT.
// Game speed-runs as a screensaver. Original: https://github.com/orta/SpeedS-ver

import Cocoa
import ScreenSaver
import AVFoundation
import AVKit

@objc(GamesScreensaverView)
final class GamesScreensaverView: ScreenSaverView {

    private let library = VideoLibrary.load()
    private let defaults = SaverDefaults()

    private let player = AVQueuePlayer()
    private var playerLayer: AVPlayerLayer!
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    private var stallObserver: NSObjectProtocol?
    private var statusObs: NSKeyValueObservation?

    private var pending: DispatchWorkItem?
    private var loadTimeout: DispatchWorkItem?
    private var lastLoadAt: Date = .distantPast
    private let minGap: TimeInterval = 1.5
    private let stallDeadline: TimeInterval = 12

    private let osd = OSDView()
    private var timeObserver: Any?
    private var currentVideo: (name: String, console: String)?

    private let spinner: NSProgressIndicator = {
        let s = NSProgressIndicator()
        s.style = .spinning
        s.isIndeterminate = true
        s.controlSize = .regular
        s.appearance = NSAppearance(named: .darkAqua)
        return s
    }()

    private let titleLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.alignment = .center
        l.textColor = NSColor.white.withAlphaComponent(0.85)
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.maximumNumberOfLines = 2
        l.cell?.truncatesLastVisibleLine = true
        l.cell?.lineBreakMode = .byTruncatingTail
        return l
    }()

    private lazy var loadingView: NSStackView = {
        let s = NSStackView(views: [spinner, titleLabel])
        s.orientation = .vertical
        s.spacing = 14
        s.alignment = .centerX
        return s
    }()

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        autoresizingMask = [.width, .height]
        wantsLayer = true
        layer?.backgroundColor = .black

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspect
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(playerLayer)

        player.actionAtItemEnd = .none
        player.isMuted = defaults.muted

        addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.7),
        ])

        osd.translatesAutoresizingMaskIntoConstraints = false
        addSubview(osd)
        NSLayoutConstraint.activate([
            osd.leadingAnchor.constraint(equalTo: leadingAnchor),
            osd.trailingAnchor.constraint(equalTo: trailingAnchor),
            osd.topAnchor.constraint(equalTo: topAnchor),
            osd.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        osd.apply(defaults.osd)

        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 4), queue: .main) { [weak self] _ in
            self?.refreshOSDProgress()
        }

        let nc = NotificationCenter.default
        endObserver = nc.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            self?.playNext()
        }
        failObserver = nc.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            self?.playNext()
        }
        stallObserver = nc.addObserver(forName: .AVPlayerItemNewErrorLogEntry, object: nil, queue: .main) { [weak self] note in
            guard let item = note.object as? AVPlayerItem,
                  let entry = item.errorLog()?.events.last,
                  entry.errorStatusCode >= 400 else { return }
            self?.playNext()
        }
        statusObs = player.observe(\.timeControlStatus, options: [.new]) { [weak self] p, _ in
            DispatchQueue.main.async {
                if p.timeControlStatus == .playing { self?.hideLoading() }
            }
        }
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        [endObserver, failObserver, stallObserver].compactMap { $0 }.forEach(NotificationCenter.default.removeObserver)
        if let timeObserver { player.removeTimeObserver(timeObserver) }
    }

    override func startAnimation() {
        super.startAnimation()
        playNext()
    }

    override func stopAnimation() {
        super.stopAnimation()
        player.pause()
        pending?.cancel()
        loadTimeout?.cancel()
    }

    override func animateOneFrame() {}

    private func playNext() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.loadOne() }
        pending = work
        let wait = max(0, minGap - Date().timeIntervalSince(lastLoadAt))
        DispatchQueue.main.asyncAfter(deadline: .now() + wait, execute: work)
    }

    private func loadOne() {
        lastLoadAt = Date()
        guard let v = library.pickRandom(enabled: defaults.enabledConsoles),
              let url = URL(string: v.urlString) else { return }
        currentVideo = (v.name, v.console)
        showLoading(title: v.name)
        osd.setMeta(title: v.name, console: v.console)
        osd.resetProgress()
        let item = AVPlayerItem(url: url)
        player.removeAllItems()
        player.insert(item, after: nil)
        player.isMuted = defaults.muted
        player.play()

        loadTimeout?.cancel()
        let timeout = DispatchWorkItem { [weak self] in self?.playNext() }
        loadTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + stallDeadline, execute: timeout)
    }

    private func refreshOSDProgress() {
        guard let item = player.currentItem else { return }
        let elapsed = CMTimeGetSeconds(item.currentTime())
        let total = CMTimeGetSeconds(item.duration)
        osd.setProgress(elapsed: elapsed, total: total)
    }

    private func showLoading(title: String) {
        titleLabel.stringValue = title
        loadingView.isHidden = false
        spinner.startAnimation(nil)
    }

    private func hideLoading() {
        loadTimeout?.cancel()
        spinner.stopAnimation(nil)
        loadingView.isHidden = true
    }

    // MARK: configure sheet

    private var sheetWindow: NSWindow?

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        if let w = sheetWindow { return w }
        let w = SettingsWindow.make(library: library, defaults: defaults) { [weak self] in
            guard let self, let w = self.sheetWindow else { return }
            w.sheetParent?.endSheet(w)
            w.orderOut(nil)
            self.player.isMuted = self.defaults.muted
            self.osd.apply(self.defaults.osd)
            self.playNext()
        }
        sheetWindow = w
        return w
    }
}
