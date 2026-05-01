// SpeedS@ver - based on the original by orta therox (2013), MIT.

import Cocoa
import AVFoundation

enum OSDSize: String, CaseIterable, Equatable {
    case small, medium, large, xlarge

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xlarge: return "Extra large"
        }
    }

    var titleFont: NSFont {
        switch self {
        case .small: return .systemFont(ofSize: 13, weight: .medium)
        case .medium: return .systemFont(ofSize: 17, weight: .medium)
        case .large: return .systemFont(ofSize: 22, weight: .medium)
        case .xlarge: return .systemFont(ofSize: 30, weight: .semibold)
        }
    }

    var consoleFont: NSFont {
        switch self {
        case .small: return .monospacedSystemFont(ofSize: 11, weight: .bold)
        case .medium: return .monospacedSystemFont(ofSize: 13, weight: .bold)
        case .large: return .monospacedSystemFont(ofSize: 16, weight: .bold)
        case .xlarge: return .monospacedSystemFont(ofSize: 22, weight: .bold)
        }
    }

    var timeFont: NSFont {
        switch self {
        case .small: return .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        case .medium: return .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        case .large: return .monospacedDigitSystemFont(ofSize: 18, weight: .regular)
        case .xlarge: return .monospacedDigitSystemFont(ofSize: 24, weight: .regular)
        }
    }

    var pillPadding: NSEdgeInsets {
        switch self {
        case .small: return NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        case .medium: return NSEdgeInsets(top: 9, left: 16, bottom: 9, right: 16)
        case .large: return NSEdgeInsets(top: 12, left: 22, bottom: 12, right: 22)
        case .xlarge: return NSEdgeInsets(top: 16, left: 28, bottom: 16, right: 28)
        }
    }

    var screenMargin: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 22
        case .large: return 28
        case .xlarge: return 36
        }
    }
}

struct OSDFlags: Equatable {
    var enabled: Bool
    var title: Bool
    var console: Bool
    var progress: Bool
    var time: Bool
    var size: OSDSize
}

final class OSDView: NSView {

    private let topPill = Pill()
    private let bottomPill = Pill()

    private let consoleLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let elapsedLabel = NSTextField(labelWithString: "")
    private let totalLabel = NSTextField(labelWithString: "")
    private let progressBar = ThinProgressBar()

    private var topMargin: NSLayoutConstraint!
    private var bottomMargin: NSLayoutConstraint!
    private var topMaxWidth: NSLayoutConstraint!
    private var bottomMaxWidth: NSLayoutConstraint!
    private var progressWidth: NSLayoutConstraint!

    private var flags = OSDFlags(enabled: true, title: true, console: true, progress: true, time: false, size: .medium)

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { nil }

    private func setup() {
        wantsLayer = true

        // Top pill: console chip + title
        consoleLabel.textColor = .white
        consoleLabel.alphaValue = 0.95
        titleLabel.textColor = .white
        titleLabel.alphaValue = 0.95
        titleLabel.maximumNumberOfLines = 1
        titleLabel.cell?.lineBreakMode = .byTruncatingMiddle
        topPill.setContent([consoleLabel, titleLabel], spacing: 12)

        // Bottom pill: elapsed + progress + total
        elapsedLabel.textColor = .white.withAlphaComponent(0.9)
        totalLabel.textColor = .white.withAlphaComponent(0.6)
        bottomPill.setContent([elapsedLabel, progressBar, totalLabel], spacing: 12)

        for v in [topPill, bottomPill] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }

        topMargin = topPill.topAnchor.constraint(equalTo: topAnchor, constant: 22)
        bottomMargin = bottomPill.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -22)
        topMaxWidth = topPill.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.85)
        bottomMaxWidth = bottomPill.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.85)
        progressWidth = progressBar.widthAnchor.constraint(equalToConstant: 240)
        NSLayoutConstraint.activate([
            topPill.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomPill.centerXAnchor.constraint(equalTo: centerXAnchor),
            topMargin, bottomMargin, topMaxWidth, bottomMaxWidth, progressWidth,
        ])
    }

    func setMeta(title: String, console: String) {
        titleLabel.stringValue = title
        consoleLabel.stringValue = console.uppercased()
    }

    func setProgress(elapsed: Double, total: Double) {
        guard total > 0 else { return }
        progressBar.fraction = max(0, min(1, elapsed / total))
        elapsedLabel.stringValue = formatTime(elapsed)
        totalLabel.stringValue = formatTime(total)
    }

    func resetProgress() {
        progressBar.fraction = 0
        elapsedLabel.stringValue = "--:--"
        totalLabel.stringValue = "--:--"
    }

    func apply(_ f: OSDFlags) {
        let sizeChanged = (flags.size != f.size)
        flags = f

        consoleLabel.font = f.size.consoleFont
        titleLabel.font = f.size.titleFont
        elapsedLabel.font = f.size.timeFont
        totalLabel.font = f.size.timeFont

        topPill.padding = f.size.pillPadding
        bottomPill.padding = f.size.pillPadding
        topMargin.constant = f.size.screenMargin
        bottomMargin.constant = -f.size.screenMargin

        switch f.size {
        case .small: progressWidth.constant = 180
        case .medium: progressWidth.constant = 260
        case .large: progressWidth.constant = 340
        case .xlarge: progressWidth.constant = 440
        }

        consoleLabel.isHidden = !(f.enabled && f.console)
        titleLabel.isHidden = !(f.enabled && f.title)
        progressBar.isHidden = !(f.enabled && f.progress)
        elapsedLabel.isHidden = !(f.enabled && f.time)
        totalLabel.isHidden = !(f.enabled && f.time)

        topPill.isHidden = consoleLabel.isHidden && titleLabel.isHidden
        bottomPill.isHidden = progressBar.isHidden && elapsedLabel.isHidden

        if sizeChanged { needsLayout = true }
    }
}

private final class Pill: NSView {
    var padding: NSEdgeInsets = NSEdgeInsets(top: 9, left: 16, bottom: 9, right: 16) {
        didSet { needsLayout = true }
    }

    private let blur: NSVisualEffectView = {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.blendingMode = .withinWindow
        v.state = .active
        v.appearance = NSAppearance(named: .vibrantDark)
        return v
    }()
    private let stack = NSStackView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = true
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor

        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12
        addSubview(stack)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        relayoutStack()
    }

    required init?(coder: NSCoder) { nil }

    func setContent(_ views: [NSView], spacing: CGFloat) {
        stack.spacing = spacing
        for v in stack.arrangedSubviews { stack.removeArrangedSubview(v); v.removeFromSuperview() }
        for v in views { stack.addArrangedSubview(v) }
    }

    private var stackConstraints: [NSLayoutConstraint] = []

    override func layout() {
        super.layout()
        layer?.cornerRadius = min(20, bounds.height / 2)
    }

    private func relayoutStack() {
        NSLayoutConstraint.deactivate(stackConstraints)
        stackConstraints = [
            stack.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding.right),
        ]
        NSLayoutConstraint.activate(stackConstraints)
    }

    override func updateConstraints() {
        relayoutStack()
        super.updateConstraints()
    }
}

private final class ThinProgressBar: NSView {
    var fraction: Double = 0 { didSet { needsDisplay = true } }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: NSSize { NSSize(width: NSView.noIntrinsicMetric, height: 4) }

    override func draw(_ dirtyRect: NSRect) {
        let h: CGFloat = 4
        let track = NSRect(x: 0, y: (bounds.height - h) / 2, width: bounds.width, height: h)
        let trackPath = NSBezierPath(roundedRect: track, xRadius: h / 2, yRadius: h / 2)
        NSColor.white.withAlphaComponent(0.18).setFill()
        trackPath.fill()

        let filledWidth = max(h, track.width * CGFloat(fraction))
        let filled = NSRect(x: 0, y: track.minY, width: filledWidth, height: h)
        let filledPath = NSBezierPath(roundedRect: filled, xRadius: h / 2, yRadius: h / 2)
        NSColor.white.withAlphaComponent(0.95).setFill()
        filledPath.fill()
    }
}

private func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "--:--" }
    let s = Int(seconds)
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
}
