import AppKit

struct NoteDates: Codable {
    var createdAt: Date
    var updatedAt: Date
}

enum NoteSort: Int, CaseIterable {
    case updatedNewest, updatedOldest, createdNewest, createdOldest, titleAZ, titleZA
    var title: String {
        switch self {
        case .updatedNewest: "Güncelleme: en yeni önce"
        case .updatedOldest: "Güncelleme: en eski önce"
        case .createdNewest: "Eklenme: en yeni önce"
        case .createdOldest: "Eklenme: en eski önce"
        case .titleAZ: "Başlık: A → Z"
        case .titleZA: "Başlık: Z → A"
        }
    }
}

struct Palette {
    let name: String
    let color: NSColor
}
let palettes: [Palette] = [
    .init(name: "Gece", color: NSColor(srgbRed: 0.052, green: 0.062, blue: 0.086, alpha: 1)),
    .init(name: "Kâğıt", color: NSColor(srgbRed: 0.965, green: 0.945, blue: 0.895, alpha: 1)),
    .init(name: "Orman", color: NSColor(srgbRed: 0.078, green: 0.176, blue: 0.149, alpha: 1)),
    .init(name: "Okyanus", color: NSColor(srgbRed: 0.070, green: 0.164, blue: 0.262, alpha: 1)),
    .init(name: "Lavanta", color: NSColor(srgbRed: 0.842, green: 0.812, blue: 0.918, alpha: 1)),
    .init(name: "Kum", color: NSColor(srgbRed: 0.868, green: 0.774, blue: 0.628, alpha: 1)),
    .init(name: "Gül", color: NSColor(srgbRed: 0.938, green: 0.822, blue: 0.812, alpha: 1)),
    .init(name: "Kömür", color: NSColor(srgbRed: 0.148, green: 0.148, blue: 0.156, alpha: 1)),
    .init(name: "Adaçayı", color: NSColor(srgbRed: 0.752, green: 0.822, blue: 0.730, alpha: 1)),
    .init(name: "Beyaz", color: NSColor(srgbRed: 0.988, green: 0.984, blue: 0.975, alpha: 1))
]
let sceneNames = ["Sisli Dağlar", "Gün Batımı", "Çam Ormanı", "Kum Tepeleri", "Gece Göğü", "Sakin Deniz", "Lavanta Tepeleri", "Karlı Zirveler", "Sonbahar", "Ay Işığı"]

enum Theme {
    static let accent = NSColor(srgbRed: 0.796, green: 0.678, blue: 0.470, alpha: 1)
    static let sidebarWidth: CGFloat = 332
    static let columnWidth: CGFloat = 720
    static let writingSize: CGFloat = 21

    static func writingFont(_ size: CGFloat = writingSize, italic: Bool = false) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: .regular)
        if let descriptor = base.fontDescriptor.withDesign(.serif), let font = NSFont(descriptor: descriptor, size: size) {
            return italic ? NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) : font
        }
        return italic ? NSFontManager.shared.convert(base, toHaveTrait: .italicFontMask) : base
    }

    static func sans(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
        .systemFont(ofSize: size, weight: weight)
    }

    static func tracking(_ size: CGFloat) -> [NSAttributedString.Key: Any] {
        [.font: sans(size, .semibold), .kern: 1.4, .foregroundColor: NSColor.white.withAlphaComponent(0.55)]
    }

    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

@MainActor
final class FocusWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class WritingClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var constrained = super.constrainBoundsRect(proposedBounds)
        constrained.origin.x = 0
        return constrained
    }
}

@MainActor
final class FlippedStackView: NSStackView {
    override var isFlipped: Bool { true }
}

final class SidebarPanel: NSVisualEffectView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.withAlphaComponent(0.34).setFill(); bounds.fill()
        NSColor.white.withAlphaComponent(0.07).setFill()
        NSRect(x: bounds.maxX - 1, y: 0, width: 1, height: bounds.height).fill()
    }
}

@MainActor
final class FilledButton: NSButton {
    private let label: String
    private let showsPlus: Bool
    private var isHovered = false { didSet { needsDisplay = true } }
    private var isPressed = false { didSet { needsDisplay = true } }

    init(title: String, plus: Bool = false, action: Selector, target: AnyObject) {
        label = title
        showsPlus = plus
        super.init(frame: .zero)
        self.target = target
        self.action = action
        isBordered = false
        focusRingType = .none
        wantsLayer = true
        setAccessibilityLabel(title)
        setButtonType(.momentaryChange)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self))
    }
    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func mouseDown(with event: NSEvent) {
        isPressed = true
        super.mouseDown(with: event)
        isPressed = false
    }

    private var ink: NSColor { NSColor(srgbRed: 0.098, green: 0.086, blue: 0.063, alpha: 1) }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let shape = NSBezierPath(roundedRect: rect, xRadius: 11, yRadius: 11)
        let lift: CGFloat = isPressed ? 0 : 1

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(isPressed ? 0.20 : 0.34)
        shadow.shadowBlurRadius = isPressed ? 4 : 12
        shadow.shadowOffset = NSSize(width: 0, height: -lift * 2)
        shadow.set()
        Theme.accent.setFill()
        shape.fill()
        NSGraphicsContext.restoreGraphicsState()

        let highlight = Theme.accent.blended(withFraction: isHovered ? 0.24 : 0.13, of: .white) ?? Theme.accent
        let shade = Theme.accent.blended(withFraction: isPressed ? 0.10 : 0.0, of: .black) ?? Theme.accent
        NSGradient(starting: shade, ending: highlight)?.draw(in: shape, angle: 90)

        NSGraphicsContext.saveGraphicsState()
        shape.addClip()
        NSColor.white.withAlphaComponent(isHovered ? 0.22 : 0.14).setStroke()
        let sheen = NSBezierPath(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75), xRadius: 10, yRadius: 10)
        sheen.lineWidth = 1
        sheen.stroke()
        NSGraphicsContext.restoreGraphicsState()

        let font = NSFont.systemFont(ofSize: 12.5, weight: .semibold)
        let textSize = (label as NSString).size(withAttributes: [.font: font])
        let plusSize: CGFloat = showsPlus ? 13 : 0
        let gap: CGFloat = showsPlus ? 8 : 0
        let total = textSize.width + plusSize + gap
        let startX = (bounds.width - total) / 2
        let baselineShift = isPressed ? -0.5 : 0

        if showsPlus {
            ink.setStroke()
            let center = NSPoint(x: startX + plusSize / 2, y: bounds.midY + baselineShift)
            let stroke = NSBezierPath()
            stroke.lineWidth = 1.8
            stroke.lineCapStyle = .round
            stroke.move(to: NSPoint(x: center.x - 4.5, y: center.y))
            stroke.line(to: NSPoint(x: center.x + 4.5, y: center.y))
            stroke.move(to: NSPoint(x: center.x, y: center.y - 4.5))
            stroke.line(to: NSPoint(x: center.x, y: center.y + 4.5))
            stroke.stroke()
        }

        NSAttributedString(string: label, attributes: [.font: font, .foregroundColor: ink])
            .draw(at: NSPoint(x: startX + plusSize + gap, y: bounds.midY - textSize.height / 2 + 0.5 + baselineShift))
    }
}

@MainActor
final class NoteRow: NSView {
    var noteID: String
    var isSelectedNote: Bool { didSet { needsDisplay = true; refreshDelete() } }
    private var isHovered = false { didSet { needsDisplay = true; refreshDelete() } }
    var onSelect: ((String) -> Void)?
    var onDelete: ((String) -> Void)?
    private let deleteButton = NSButton()
    private var tracking: NSTrackingArea?

    init(id: String, title: String, subtitle: String, selected: Bool) {
        noteID = id; isSelectedNote = selected
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13.5, weight: selected ? .semibold : .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(selected ? 0.97 : 0.82)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let dateLabel = NSTextField(labelWithString: subtitle)
        dateLabel.font = .systemFont(ofSize: 11, weight: .regular)
        dateLabel.textColor = NSColor.white.withAlphaComponent(selected ? 0.52 : 0.38)
        dateLabel.lineBreakMode = .byTruncatingTail
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        deleteButton.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Yazıyı sil")
        deleteButton.isBordered = false
        deleteButton.contentTintColor = NSColor.white.withAlphaComponent(0.45)
        deleteButton.target = self; deleteButton.action = #selector(deleteTapped)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.toolTip = "Yazıyı Çöp Sepeti’ne taşı"
        deleteButton.alphaValue = 0

        addSubview(titleLabel); addSubview(dateLabel); addSubview(deleteButton)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 58),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -6),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private func refreshDelete() { deleteButton.alphaValue = (isHovered || isSelectedNote) ? 1 : 0 }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area); tracking = area
    }
    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func mouseDown(with event: NSEvent) { onSelect?(noteID) }
    @objc private func deleteTapped() { onDelete?(noteID) }

    override func draw(_ dirtyRect: NSRect) {
        let card = NSBezierPath(roundedRect: bounds.insetBy(dx: 0, dy: 2), xRadius: 11, yRadius: 11)
        if isSelectedNote {
            NSColor.white.withAlphaComponent(0.09).setFill(); card.fill()
            Theme.accent.withAlphaComponent(0.92).setFill()
            NSBezierPath(roundedRect: NSRect(x: 0, y: bounds.midY - 12, width: 2.5, height: 24), xRadius: 1.25, yRadius: 1.25).fill()
        } else if isHovered {
            NSColor.white.withAlphaComponent(0.05).setFill(); card.fill()
        }
    }
}

@MainActor
final class FooterButton: NSButton {
    private var hoverArea: NSTrackingArea?
    init(title: String, symbol: String, action: Selector, target: AnyObject) {
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        wantsLayer = true
        focusRingType = .none
        layer?.cornerRadius = 8
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.isTemplate = true
        self.image = image
        imagePosition = .imageLeading
        contentTintColor = NSColor.white.withAlphaComponent(0.62)
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 11.5, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.62)
        ])
        heightAnchor.constraint(equalToConstant: 28).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area); hoverArea = area
    }
    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.07).cgColor
        contentTintColor = NSColor.white.withAlphaComponent(0.92)
    }
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = NSColor.clear.cgColor
        contentTintColor = NSColor.white.withAlphaComponent(0.62)
    }
}

@MainActor
final class HUDView: NSView {
    private let wordLabel = NSTextField(labelWithString: "0 kelime")
    private let saveLabel = NSTextField(labelWithString: "Kaydedildi")
    private let dot = NSView()
    private var tracking: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 15
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.28).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.10).cgColor

        wordLabel.font = .monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
        wordLabel.textColor = NSColor.white.withAlphaComponent(0.52)
        saveLabel.font = .systemFont(ofSize: 10.5, weight: .medium)
        saveLabel.textColor = NSColor.white.withAlphaComponent(0.40)
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 2.5
        dot.layer?.backgroundColor = Theme.accent.withAlphaComponent(0.85).cgColor
        [wordLabel, saveLabel, dot].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 5),
            dot.heightAnchor.constraint(equalToConstant: 5),
            wordLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 8),
            wordLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            saveLabel.leadingAnchor.constraint(equalTo: wordLabel.trailingAnchor, constant: 10),
            saveLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13),
            saveLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(words: Int, saved: Bool) {
        wordLabel.stringValue = words == 1 ? "1 kelime" : "\(words) kelime"
        saveLabel.stringValue = saved ? "Kaydedildi" : "Yazıyor…"
        dot.layer?.backgroundColor = (saved ? Theme.accent : NSColor.white).withAlphaComponent(0.85).cgColor
    }
}

@MainActor
final class GhostButton: NSButton {
    private var hoverArea: NSTrackingArea?
    private let baseColor: NSColor

    init(title: String, symbol: String? = nil, destructive: Bool = false, action: Selector, target: AnyObject) {
        baseColor = destructive
            ? NSColor(srgbRed: 0.95, green: 0.60, blue: 0.54, alpha: 1)
            : NSColor.white.withAlphaComponent(0.62)
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        wantsLayer = true
        focusRingType = .none
        layer?.cornerRadius = 11
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 12.5, weight: .medium),
            .foregroundColor: baseColor
        ])
        if let symbol {
            let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 11.5, weight: .medium))
            image?.isTemplate = true
            self.image = image
            imagePosition = .imageLeading
            imageHugsTitle = true
            contentTintColor = baseColor
        }
        heightAnchor.constraint(equalToConstant: 34).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area); hoverArea = area
    }
    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.07).cgColor
        contentTintColor = NSColor.white.withAlphaComponent(0.92)
    }
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = NSColor.clear.cgColor
        contentTintColor = baseColor
    }
}

@MainActor
final class CardBackground: NSVisualEffectView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let radius = max(bounds.width, bounds.height) * 0.85
        NSGradient(colors: [Theme.accent.withAlphaComponent(0.13), Theme.accent.withAlphaComponent(0)])?
            .draw(in: NSBezierPath(ovalIn: NSRect(x: -radius * 0.30, y: bounds.height - radius * 0.58, width: radius, height: radius)), relativeCenterPosition: .zero)
        NSColor.white.withAlphaComponent(0.10).setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 16, yRadius: 16)
        border.lineWidth = 1
        border.stroke()
    }
}

@MainActor
final class SwatchButton: NSButton {
    private let palette: Palette
    var isActive = false { didSet { needsDisplay = true } }
    private var isHovered = false { didSet { needsDisplay = true } }

    init(palette: Palette, index: Int, target: AnyObject, action: Selector) {
        self.palette = palette
        super.init(frame: .zero)
        tag = index
        self.target = target
        self.action = action
        isBordered = false
        focusRingType = .none
        wantsLayer = true
        setAccessibilityLabel(palette.name)
        toolTip = palette.name
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 42).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self))
    }
    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }

    override func draw(_ dirtyRect: NSRect) {
        let card = NSBezierPath(roundedRect: bounds.insetBy(dx: 0, dy: 1), xRadius: 10, yRadius: 10)
        if isActive {
            NSColor.white.withAlphaComponent(0.09).setFill(); card.fill()
            Theme.accent.withAlphaComponent(0.75).setStroke()
            card.lineWidth = 1
            card.stroke()
        } else if isHovered {
            NSColor.white.withAlphaComponent(0.05).setFill(); card.fill()
        }
        let swatch = NSRect(x: 11, y: bounds.midY - 8, width: 16, height: 16)
        let dot = NSBezierPath(ovalIn: swatch)
        palette.color.setFill(); dot.fill()
        NSColor.white.withAlphaComponent(isActive ? 0.55 : 0.22).setStroke()
        dot.lineWidth = 1
        dot.stroke()
        NSAttributedString(string: palette.name, attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: isActive ? .semibold : .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(isActive ? 0.96 : 0.72)
        ]).draw(in: NSRect(x: swatch.maxX + 9, y: bounds.midY - 8, width: bounds.width - swatch.maxX - 14, height: 16))
    }
}

@MainActor
final class SceneTile: NSButton {
    private let sceneName: String
    private let thumbnail: NSImage
    var isActive = false { didSet { needsDisplay = true } }
    private var isHovered = false { didSet { needsDisplay = true } }

    init(index: Int, name: String, image: NSImage, target: AnyObject, action: Selector) {
        sceneName = name; thumbnail = image
        super.init(frame: .zero)
        tag = index
        self.target = target
        self.action = action
        isBordered = false
        focusRingType = .none
        wantsLayer = true
        setAccessibilityLabel(name)
        toolTip = name
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 92).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self))
    }
    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }

    override func draw(_ dirtyRect: NSRect) {
        let captionHeight: CGFloat = 18
        let frame = NSRect(x: 1, y: 0, width: bounds.width - 2, height: bounds.height - captionHeight)
        let shape = NSBezierPath(roundedRect: frame, xRadius: 9, yRadius: 9)
        NSGraphicsContext.saveGraphicsState()
        shape.addClip()
        thumbnail.draw(in: frame, from: .zero, operation: .sourceOver, fraction: isHovered || isActive ? 1 : 0.72)
        if isActive {
            NSColor.black.withAlphaComponent(0.14).setFill(); frame.fill()
        }
        NSGraphicsContext.restoreGraphicsState()
        (isActive ? Theme.accent.withAlphaComponent(0.9) : NSColor.white.withAlphaComponent(isHovered ? 0.30 : 0.12)).setStroke()
        shape.lineWidth = isActive ? 2 : 1
        shape.stroke()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail
        NSAttributedString(string: sceneName, attributes: [
            .font: NSFont.systemFont(ofSize: 10.5, weight: isActive ? .semibold : .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(isActive ? 0.96 : 0.58),
            .paragraphStyle: paragraph
        ]).draw(in: NSRect(x: 0, y: bounds.height - captionHeight + 3, width: bounds.width, height: 15))
    }
    override var isFlipped: Bool { true }
}

@MainActor
final class FieldBox: NSView, NSTextFieldDelegate {
    let field: NSTextField

    init(value: String, placeholder: String, accessibility: String) {
        field = NSTextField(string: value)
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        layer?.cornerRadius = 9
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.10).cgColor
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 13.5)
        field.textColor = NSColor.white.withAlphaComponent(0.94)
        field.placeholderString = placeholder
        field.setAccessibilityLabel(accessibility)
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        addSubview(field)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 38),
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            field.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(field) }
    func controlTextDidBeginEditing(_ obj: Notification) {
        layer?.borderColor = Theme.accent.withAlphaComponent(0.55).cgColor
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        layer?.borderColor = NSColor.white.withAlphaComponent(0.10).cgColor
    }
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
        onSubmit?()
        return true
    }
    var onSubmit: (() -> Void)?
}

@MainActor
final class LinkSheet: NSPanel {
    var onSubmit: ((String, URL) -> Void)?
    var onRemove: (() -> Void)?
    var onDismiss: (() -> Void)?

    private let textBox: FieldBox
    private let addressBox: FieldBox
    private let errorLabel = NSTextField(labelWithString: "")
    private let hasExisting: Bool
    private var addButton: FilledButton!

    init(selectedText: String, existingURL: String?) {
        let existing = (existingURL?.isEmpty == false) ? existingURL : nil
        hasExisting = existing != nil
        textBox = FieldBox(value: selectedText, placeholder: "Bağlantı metni", accessibility: "Bağlantı metni")
        addressBox = FieldBox(value: existing ?? "", placeholder: "https://ornek.com", accessibility: "Bağlantı adresi")
        super.init(contentRect: NSRect(x: 0, y: 0, width: 448, height: 380), styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        appearance = NSAppearance(named: .darkAqua)
        [.closeButton, .miniaturizeButton, .zoomButton].forEach { standardWindowButton($0)?.isHidden = true }
        addButton = FilledButton(title: hasExisting ? "Kaydet" : "Ekle", action: #selector(submit), target: self)

        let background = CardBackground()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.appearance = NSAppearance(named: .darkAqua)
        background.wantsLayer = true
        background.layer?.cornerRadius = 16
        background.layer?.masksToBounds = true
        contentView = background

        func caption(_ text: String) -> NSTextField {
            NSTextField(labelWithAttributedString: NSAttributedString(string: text, attributes: [
                .font: NSFont.systemFont(ofSize: 9.5, weight: .semibold),
                .kern: 1.2,
                .foregroundColor: NSColor.white.withAlphaComponent(0.42)
            ]))
        }

        let eyebrow = NSTextField(labelWithAttributedString: NSAttributedString(string: "BAĞLANTI", attributes: Theme.tracking(9)))
        let heading = NSTextField(labelWithString: hasExisting ? "Bağlantıyı düzenle" : "Bağlantı ekle")
        heading.font = Theme.writingFont(25)
        heading.textColor = NSColor.white.withAlphaComponent(0.96)
        let subtitle = NSTextField(wrappingLabelWithString: "Açmak için ⌘ tuşuyla tıkla. Adres yoksa https:// eklenir.")
        subtitle.font = .systemFont(ofSize: 11.5)
        subtitle.textColor = NSColor.white.withAlphaComponent(0.48)
        subtitle.preferredMaxLayoutWidth = 392

        errorLabel.font = .systemFont(ofSize: 11.5, weight: .medium)
        errorLabel.textColor = NSColor(srgbRed: 0.95, green: 0.60, blue: 0.54, alpha: 1)
        errorLabel.isHidden = true

        textBox.onSubmit = { [weak self] in self?.focusAddress() }
        addressBox.onSubmit = { [weak self] in self?.submit() }
        textBox.field.nextKeyView = addressBox.field
        addressBox.field.nextKeyView = textBox.field

        addButton.widthAnchor.constraint(equalToConstant: 92).isActive = true
        let cancel = GhostButton(title: "İptal", action: #selector(cancel), target: self)
        cancel.widthAnchor.constraint(equalToConstant: 82).isActive = true
        let buttons = NSStackView(views: [NSView(), cancel, addButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8

        let textCaption = caption("METİN")
        let addressCaption = caption("ADRES")
        var arranged: [NSView] = [eyebrow, heading, subtitle, textCaption, textBox, addressCaption, addressBox, errorLabel]
        if hasExisting {
            let remove = GhostButton(title: "Bağlantıyı kaldır", symbol: "link.badge.plus", destructive: true, action: #selector(removeLink), target: self)
            let row = NSStackView(views: [remove, NSView()])
            row.orientation = .horizontal
            arranged.append(row)
        }
        arranged.append(buttons)

        let stack = NSStackView(views: arranged)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.setCustomSpacing(5, after: eyebrow)
        stack.setCustomSpacing(6, after: heading)
        stack.setCustomSpacing(18, after: subtitle)
        stack.setCustomSpacing(6, after: textCaption)
        stack.setCustomSpacing(13, after: textBox)
        stack.setCustomSpacing(16, after: errorLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: background.topAnchor, constant: 32),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: background.bottomAnchor, constant: -24)
        ])
        [textBox, addressBox, buttons].forEach { $0.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        if hasExisting, let row = arranged.first(where: { $0 is NSStackView }) { row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        setContentSize(NSSize(width: 448, height: stack.fittingSize.height + 56))
    }
    required init?(coder: NSCoder) { fatalError() }

    func present(in parent: NSWindow) {
        parent.beginSheet(self)
        makeFirstResponder(addressBox.field)
        addressBox.field.selectText(nil)
    }
    @objc private func focusAddress() { makeFirstResponder(addressBox.field) }
    @objc private func cancel() { dismiss() }
    @objc private func removeLink() { dismiss(); onRemove?() }
    override func cancelOperation(_ sender: Any?) { dismiss() }

    func dismiss() {
        if let parent = sheetParent { parent.endSheet(self) } else { orderOut(nil) }
        onDismiss?()
    }
    @objc private func submit() {
        guard let url = normalizedURL(addressBox.field.stringValue) else {
            errorLabel.stringValue = "Geçerli bir http, https veya mailto adresi gir."
            errorLabel.isHidden = false
            NSSound.beep()
            makeFirstResponder(addressBox.field)
            return
        }
        var title = textBox.field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty { title = url.absoluteString }
        dismiss()
        onSubmit?(title, url)
    }
    private func normalizedURL(_ raw: String) -> URL? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if !value.contains(":") { value = "https://" + value }
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased(),
              ["https", "http", "mailto"].contains(scheme),
              (scheme == "mailto" ? !url.path.isEmpty : url.host?.isEmpty == false) else { return nil }
        return url
    }
}

@MainActor
final class Background: NSView {
    var picture: NSImage?
    var color: NSColor = palettes[0].color
    override func draw(_ dirtyRect: NSRect) {
        color.setFill(); bounds.fill()
        if let picture {
            let scale = max(bounds.width / picture.size.width, bounds.height / picture.size.height)
            let size = NSSize(width: picture.size.width * scale, height: picture.size.height * scale)
            picture.draw(in: NSRect(x: (bounds.width-size.width)/2, y: (bounds.height-size.height)/2, width: size.width, height: size.height))
            NSColor.black.withAlphaComponent(0.52).setFill(); bounds.fill()
        } else {
            let radius = max(bounds.width, bounds.height) * 0.78
            NSGradient(colors: [NSColor.black.withAlphaComponent(0), NSColor.black.withAlphaComponent(0.30)])!
                .draw(in: NSBezierPath(ovalIn: NSRect(x: bounds.midX - radius, y: bounds.midY - radius * 0.62, width: radius * 2, height: radius * 1.24)), relativeCenterPosition: .zero)
        }
    }
}

@MainActor
func landscape(_ index: Int) -> NSImage {
    let size = NSSize(width: 1920, height: 1200)
    return NSImage(size: size, flipped: false) { rect in
        struct Scene {
            let top: NSColor
            let bottom: NSColor
            let glow: NSColor
            let glowSize: CGFloat
            let glowX: CGFloat
            let glowY: CGFloat
            let ridge: (CGFloat, CGFloat, CGFloat)
            let amplitude: CGFloat
            let trees: Bool
        }
        let d = { (r: Double, g: Double, b: Double) in NSColor(srgbRed: r, green: g, blue: b, alpha: 1) }
        let scenes: [Scene] = [
            Scene(top: d(0.32, 0.42, 0.47), bottom: d(0.76, 0.80, 0.78), glow: d(1, 0.95, 0.86), glowSize: 260, glowX: 0.28, glowY: 0.30, ridge: (0.35, 0.42, 0.46), amplitude: 120, trees: false),
            Scene(top: d(0.24, 0.16, 0.36), bottom: d(0.96, 0.56, 0.34), glow: d(1, 0.82, 0.54), glowSize: 300, glowX: 0.72, glowY: 0.28, ridge: (0.30, 0.19, 0.24), amplitude: 130, trees: false),
            Scene(top: d(0.11, 0.26, 0.25), bottom: d(0.58, 0.68, 0.57), glow: d(0.93, 0.96, 0.86), glowSize: 200, glowX: 0.22, glowY: 0.34, ridge: (0.14, 0.29, 0.25), amplitude: 110, trees: true),
            Scene(top: d(0.44, 0.55, 0.63), bottom: d(0.93, 0.79, 0.58), glow: d(1, 0.92, 0.72), glowSize: 340, glowX: 0.63, glowY: 0.26, ridge: (0.80, 0.63, 0.42), amplitude: 70, trees: false),
            Scene(top: d(0.020, 0.031, 0.086), bottom: d(0.13, 0.11, 0.26), glow: d(0.86, 0.89, 1), glowSize: 190, glowX: 0.24, glowY: 0.30, ridge: (0.07, 0.09, 0.16), amplitude: 140, trees: false),
            Scene(top: d(0.26, 0.48, 0.58), bottom: d(0.82, 0.87, 0.84), glow: d(1, 0.97, 0.90), glowSize: 240, glowX: 0.78, glowY: 0.33, ridge: (0.34, 0.50, 0.54), amplitude: 55, trees: false),
            Scene(top: d(0.30, 0.26, 0.50), bottom: d(0.82, 0.68, 0.78), glow: d(1, 0.90, 0.86), glowSize: 280, glowX: 0.34, glowY: 0.27, ridge: (0.42, 0.30, 0.48), amplitude: 120, trees: false),
            Scene(top: d(0.30, 0.44, 0.60), bottom: d(0.86, 0.90, 0.92), glow: d(1, 0.99, 0.96), glowSize: 300, glowX: 0.58, glowY: 0.24, ridge: (0.70, 0.76, 0.80), amplitude: 115, trees: false),
            Scene(top: d(0.36, 0.34, 0.28), bottom: d(0.90, 0.68, 0.42), glow: d(1, 0.86, 0.60), glowSize: 260, glowX: 0.70, glowY: 0.30, ridge: (0.52, 0.34, 0.20), amplitude: 105, trees: true),
            Scene(top: d(0.024, 0.055, 0.13), bottom: d(0.20, 0.31, 0.40), glow: d(0.92, 0.95, 1), glowSize: 210, glowX: 0.66, glowY: 0.28, ridge: (0.10, 0.16, 0.24), amplitude: 125, trees: false)
        ]
        let scene = scenes[min(max(index, 0), scenes.count - 1)]

        NSGradient(starting: scene.top, ending: scene.bottom)!.draw(in: rect, angle: 90)

        // Atmospheric glow behind the sun or moon.
        let center = NSPoint(x: scene.glowX * size.width, y: scene.glowY * size.height)
        for step in stride(from: 4, through: 1, by: -1) {
            let radius = scene.glowSize * CGFloat(step) * 0.62
            NSGradient(colors: [scene.glow.withAlphaComponent(0.16), scene.glow.withAlphaComponent(0)])!
                .draw(in: NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), relativeCenterPosition: .zero)
        }
        if [4, 9].contains(index) {
            for i in 0..<190 {
                let x = CGFloat((i * 7919 + 41) % 1920), y = CGFloat((i * 3571 + 500) % 1050)
                let alpha = 0.16 + Double(i % 7) * 0.09
                scene.glow.withAlphaComponent(alpha).setFill()
                let dot = CGFloat(1 + i % 3)
                NSBezierPath(ovalIn: NSRect(x: x, y: y, width: dot, height: dot)).fill()
            }
        }
        let orbRadius: CGFloat = index == 1 ? 74 : 34
        NSGradient(colors: [scene.glow.withAlphaComponent(0.98), scene.glow.withAlphaComponent(0.55)])!
            .draw(in: NSBezierPath(ovalIn: NSRect(x: center.x - orbRadius, y: center.y - orbRadius, width: orbRadius * 2, height: orbRadius * 2)), angle: 90)

        // Layered ridges with atmospheric perspective.
        for layer in 0..<6 {
            let path = NSBezierPath()
            path.move(to: .zero)
            let base = CGFloat(520 - layer * 74)
            path.line(to: NSPoint(x: 0, y: base))
            let steps = 38
            let wave = scene.amplitude * (1 + CGFloat(layer) * 0.12)
            for step in 0...steps {
                let x = CGFloat(step) / CGFloat(steps) * size.width
                let phase = Double(step) / Double(steps) * 5.2 + Double(layer) * 1.35 + Double(index) * 0.9
                let y = base + CGFloat(sin(phase) * 0.62 + sin(phase * 2.1 + 0.7) * 0.38) * wave
                path.line(to: NSPoint(x: x, y: y))
            }
            path.line(to: NSPoint(x: size.width, y: 0))
            path.close()

            let depth = CGFloat(layer) / 5
            let shade = NSColor(
                srgbRed: scene.ridge.0 * (1 - depth * 0.55) + 0.012,
                green: scene.ridge.1 * (1 - depth * 0.55) + 0.014,
                blue: scene.ridge.2 * (1 - depth * 0.55) + 0.020,
                alpha: 1
            )
            shade.setFill(); path.fill()

            // A rim of light along the crest for the nearer layers.
            if layer >= 2 {
                scene.glow.withAlphaComponent(0.045 + Double(layer) * 0.012).setStroke()
                path.lineWidth = 1.4
                path.stroke()
            }
        }
        if scene.trees {
            for i in 0..<54 {
                let x = CGFloat(i * 37 + (index == 8 ? 11 : 0))
                let h = CGFloat(90 + (i * 73) % 170)
                let tree = NSBezierPath()
                tree.move(to: NSPoint(x: x, y: 62))
                tree.line(to: NSPoint(x: x + 26, y: 62 + h))
                tree.line(to: NSPoint(x: x + 52, y: 62))
                tree.close()
                NSColor(srgbRed: 0.028, green: 0.075, blue: 0.065, alpha: 0.55 + Double(i % 4) * 0.08).setFill()
                tree.fill()
            }
        }

        // Grain for a printed, analog feel.
        for _ in 0..<2600 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            NSColor.white.withAlphaComponent(CGFloat.random(in: 0.01...0.032)).setFill()
            NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 1.3, height: 1.3)).fill()
        }
        // Vignette keeps the eye on the column of text.
        NSGradient(colors: [NSColor.black.withAlphaComponent(0), NSColor.black.withAlphaComponent(0.38)])!
            .draw(in: NSBezierPath(rect: rect), relativeCenterPosition: NSPoint(x: 0, y: 0.18))
        return true
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSTextViewDelegate, NSWindowDelegate {
    var window: NSWindow!
    let background = Background()
    let editor = NSTextView()
    let scroll = NSScrollView()
    var settings: NSPanel?
    var swatches: [SwatchButton] = []
    var sceneTiles: [SceneTile] = []
    var settingsStatusLabel: NSTextField?
    var linkSheet: LinkSheet?
    var ink: NSColor = .white
    let sidebar = SidebarPanel()
    let noteList = FlippedStackView()
    let noteCountLabel = NSTextField(labelWithString: "")
    var noteIDs: [String] = []
    var currentNoteID = ""
    var currentNoteDirty = false
    var noteDates: [String: NoteDates] = [:]
    let sortPicker = NSPopUpButton()
    let hud = HUDView()
    var hudFadeTimer: Timer?
    var hudRevealMonitor: Any?
    let sidebarWidth = Theme.sidebarWidth
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMM yyyy · HH:mm:ss"
        return formatter
    }()
    var sortOrder: NoteSort { NoteSort(rawValue: defaults.integer(forKey: "noteSort")) ?? .updatedNewest }
    var metadataURL: URL { saveURL.deletingLastPathComponent().appendingPathComponent("NoteDates.json") }
    func persistDates() throws {
        try JSONEncoder().encode(noteDates).write(to: metadataURL, options: .atomic)
    }
    func ensureDates(_ id: String) {
        guard noteDates[id] == nil else { return }
        let values = try? noteURL(id).resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        let modified = values?.contentModificationDate ?? Date()
        let created = min(values?.creationDate ?? modified, modified)
        noteDates[id] = NoteDates(createdAt: created, updatedAt: modified)
    }
    func sortNotes() {
        let order = sortOrder
        let titles = Dictionary(uniqueKeysWithValues: noteIDs.map { ($0, titleForNote($0)) })
        noteIDs.sort { left, right in
            let lhs = noteDates[left] ?? NoteDates(createdAt: .distantPast, updatedAt: .distantPast)
            let rhs = noteDates[right] ?? NoteDates(createdAt: .distantPast, updatedAt: .distantPast)
            switch order {
            case .updatedNewest, .updatedOldest:
                if lhs.updatedAt != rhs.updatedAt { return order == .updatedNewest ? lhs.updatedAt > rhs.updatedAt : lhs.updatedAt < rhs.updatedAt }
            case .createdNewest, .createdOldest:
                if lhs.createdAt != rhs.createdAt { return order == .createdNewest ? lhs.createdAt > rhs.createdAt : lhs.createdAt < rhs.createdAt }
            case .titleAZ, .titleZA:
                let result = (titles[left] ?? "").localizedStandardCompare(titles[right] ?? "")
                if result != .orderedSame { return order == .titleAZ ? result == .orderedAscending : result == .orderedDescending }
            }
            return left < right
        }
    }
    @objc func changeSort(_ sender: NSPopUpButton) {
        defaults.set(sender.selectedTag(), forKey: "noteSort")
        rebuildNotes()
    }
    var loadingNote = false
    var eventMonitor: Any?
    var immersive = true
    var isShowingSaveError = false
    let defaults = UserDefaults.standard
    var saveURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FocusWriter")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("Draft.rtf")
    }
    var notesFolder: URL {
        saveURL.deletingLastPathComponent().appendingPathComponent("Notes", isDirectory: true)
    }
    func noteURL(_ id: String) -> URL { notesFolder.appendingPathComponent(id).appendingPathExtension("rtf") }
    func loadNotes() {
        do {
            try FileManager.default.createDirectory(at: notesFolder, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: metadataURL.path) {
                noteDates = try JSONDecoder().decode([String: NoteDates].self, from: Data(contentsOf: metadataURL))
            }
            noteIDs = try FileManager.default.contentsOfDirectory(at: notesFolder, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "rtf" }
                .sorted { ((try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast) > ((try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast) }
                .map { $0.deletingPathExtension().lastPathComponent }
            if noteIDs.isEmpty {
                let id = UUID().uuidString
                // Preserve the original draft and migrate a copy.
                if !defaults.bool(forKey: "legacyDraftMigrated") && FileManager.default.fileExists(atPath: saveURL.path) {
                    try FileManager.default.copyItem(at: saveURL, to: noteURL(id))
                } else {
                    let data = NSAttributedString(string: "").rtf(from: NSRange(location: 0, length: 0), documentAttributes: [:])!
                    try data.write(to: noteURL(id), options: .atomic)
                }
                noteIDs = [id]
            }
            for id in noteIDs { ensureDates(id) }
            try persistDates()
            defaults.set(true, forKey: "legacyDraftMigrated")
            sortNotes()
            let last = defaults.string(forKey: "activeNote") ?? ""
            openNote(noteIDs.contains(last) ? last : noteIDs[0], savingCurrent: false)
        } catch { showError(error) }
    }
    func openNote(_ id: String, savingCurrent: Bool = true) {
        if savingCurrent && !saveCurrentNote() { return }
        do {
            let data = try Data(contentsOf: noteURL(id))
            guard let text = NSAttributedString(rtf: data, documentAttributes: nil) else {
                throw NSError(domain: "FocusWriter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not okunamadı. Mevcut dosya korunuyor."])
            }
            loadingNote = true
            editor.textStorage?.setAttributedString(text)
            editor.undoManager?.removeAllActions()
            currentNoteID = id; currentNoteDirty = false; defaults.set(id, forKey: "activeNote")
            updateInk(); editor.setSelectedRange(NSRange(location: 0, length: 0))
            loadingNote = false
            editor.scrollRangeToVisible(NSRange(location: 0, length: 0))
            scroll.contentView.scroll(to: .zero)
            rebuildNotes(); hideSidebar(); window.makeFirstResponder(editor)
        } catch { loadingNote = false; showError(error) }
    }
    @objc func newNote() {
        guard saveCurrentNote() else { return }
        let id = UUID().uuidString
        do {
            let data = NSAttributedString(string: "", attributes: [.font: Theme.writingFont()]).rtf(from: NSRange(location: 0, length: 0), documentAttributes: [:])!
            try data.write(to: noteURL(id), options: .atomic)
            let now = Date(); noteDates[id] = NoteDates(createdAt: now, updatedAt: now)
            noteIDs.insert(id, at: 0)
            try persistDates()
            openNote(id, savingCurrent: false)
        } catch { showError(error) }
    }
    @objc func selectNote(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue, noteIDs.contains(id) else { return }
        openNote(id)
    }
    @objc func deleteNote(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue, noteIDs.contains(id) else { return }
        confirmDelete(id)
    }
    func confirmDelete(_ id: String) {
        guard noteIDs.contains(id) else { return }
        let alert = NSAlert()
        alert.messageText = "Yazıyı sil?"
        alert.informativeText = "“\(titleForNote(id))” Çöp Sepeti’ne taşınacak. Gerekirse Finder’dan geri alabilirsin."
        alert.addButton(withTitle: "Çöp Sepeti’ne Taşı")
        alert.addButton(withTitle: "İptal")
        alert.beginSheetModal(for: window) { response in
            guard response == .alertFirstButtonReturn, self.saveCurrentNote() else { return }
            do {
                try FileManager.default.trashItem(at: self.noteURL(id), resultingItemURL: nil)
                self.noteIDs.removeAll { $0 == id }
                if id == self.currentNoteID {
                    self.currentNoteID = ""; self.currentNoteDirty = false
                    if let next = self.noteIDs.first { self.openNote(next, savingCurrent: false) }
                    else { self.newNote() }
                }
                self.rebuildNotes()
            } catch { self.showError(error) }
        }
    }
    func titleForNote(_ id: String) -> String {
        let text: String
        if id == currentNoteID { text = editor.string }
        else { text = (try? Data(contentsOf: noteURL(id))).flatMap { NSAttributedString(rtf: $0, documentAttributes: nil)?.string } ?? "" }
        let title = text.split(whereSeparator: { $0.isNewline }).first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? ""
        return title.isEmpty ? "Yeni yazı" : String(title.prefix(48))
    }
    func rebuildNotes() {
        sortNotes()
        for view in noteList.arrangedSubviews { noteList.removeArrangedSubview(view); view.removeFromSuperview() }
        for id in noteIDs {
            let dates = noteDates[id]!
            let row = NoteRow(
                id: id,
                title: titleForNote(id),
                subtitle: "\(Theme.relativeDate(dates.updatedAt)) · \(Self.wordCountLabel(for: wordCount(id)))",
                selected: id == currentNoteID
            )
            row.onSelect = { [weak self] id in self?.openNote(id) }
            row.onDelete = { [weak self] id in self?.confirmDelete(id) }
            noteList.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: noteList.widthAnchor).isActive = true
        }
        noteCountLabel.stringValue = noteIDs.count == 1 ? "1 yazı" : "\(noteIDs.count) yazı"
    }
    func wordCount(_ id: String) -> Int {
        let text: String
        if id == currentNoteID { text = editor.string }
        else { text = (try? Data(contentsOf: noteURL(id))).flatMap { NSAttributedString(rtf: $0, documentAttributes: nil)?.string } ?? "" }
        return text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
    static func wordCountLabel(for count: Int) -> String {
        count == 1 ? "1 kelime" : "\(count) kelime"
    }
    func setupSidebar() {
        sidebar.material = .sidebar; sidebar.blendingMode = .withinWindow; sidebar.state = .active
        sidebar.appearance = NSAppearance(named: .darkAqua)
        sidebar.isHidden = true; sidebar.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(sidebar)
        NSLayoutConstraint.activate([sidebar.leadingAnchor.constraint(equalTo: background.leadingAnchor), sidebar.topAnchor.constraint(equalTo: background.topAnchor), sidebar.bottomAnchor.constraint(equalTo: background.bottomAnchor), sidebar.widthAnchor.constraint(equalToConstant: Theme.sidebarWidth)])

        let eyebrow = NSTextField(labelWithAttributedString: NSAttributedString(string: "KODMOZ WRITER", attributes: Theme.tracking(9)))
        let header = NSTextField(labelWithString: "Yazılarım")
        header.font = Theme.writingFont(30)
        header.textColor = NSColor.white.withAlphaComponent(0.96)
        noteCountLabel.font = .systemFont(ofSize: 11, weight: .medium)
        noteCountLabel.textColor = NSColor.white.withAlphaComponent(0.40)
        let headingRow = NSStackView(views: [header, NSView()])
        headingRow.orientation = .horizontal
        headingRow.addArrangedSubview(noteCountLabel)
        noteCountLabel.setContentHuggingPriority(.required, for: .horizontal)

        let newButton = FilledButton(title: "Yeni yazı", plus: true, action: #selector(newNote), target: self)

        sortPicker.addItems(withTitles: NoteSort.allCases.map(\.title))
        for (index, order) in NoteSort.allCases.enumerated() { sortPicker.item(at: index)?.tag = order.rawValue }
        sortPicker.selectItem(withTag: sortOrder.rawValue)
        sortPicker.target = self; sortPicker.action = #selector(changeSort)
        sortPicker.setAccessibilityLabel("Notları sırala")
        sortPicker.isBordered = false
        sortPicker.font = .systemFont(ofSize: 11.5, weight: .regular)
        sortPicker.contentTintColor = NSColor.white.withAlphaComponent(0.60)
        sortPicker.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let listScroll = NSScrollView(); listScroll.drawsBackground = false; listScroll.hasVerticalScroller = true; listScroll.autohidesScrollers = true
        noteList.orientation = .vertical; noteList.alignment = .leading; noteList.spacing = 2
        noteList.translatesAutoresizingMaskIntoConstraints = false; listScroll.documentView = noteList
        NSLayoutConstraint.activate([
            noteList.leadingAnchor.constraint(equalTo: listScroll.contentView.leadingAnchor),
            noteList.trailingAnchor.constraint(equalTo: listScroll.contentView.trailingAnchor),
            noteList.topAnchor.constraint(equalTo: listScroll.contentView.topAnchor),
            noteList.widthAnchor.constraint(equalTo: listScroll.contentView.widthAnchor)
        ])

        let appearance = FooterButton(title: "Görünüm ve arka plan", symbol: "paintpalette", action: #selector(showSettings), target: self)
        let hide = FooterButton(title: "Menüyü gizle", symbol: "chevron.left", action: #selector(hideSidebar), target: self)
        let footer = NSStackView(views: [appearance, hide])
        footer.orientation = .horizontal; footer.spacing = 4; footer.alignment = .centerY

        let stack = NSStackView(views: [eyebrow, headingRow, newButton, sortPicker, listScroll, footer])
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 14
        stack.setCustomSpacing(4, after: eyebrow)
        stack.setCustomSpacing(18, after: headingRow)
        stack.setCustomSpacing(10, after: newButton)
        stack.translatesAutoresizingMaskIntoConstraints = false; sidebar.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 18), stack.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: -18), stack.topAnchor.constraint(equalTo: sidebar.topAnchor, constant: 52), stack.bottomAnchor.constraint(equalTo: sidebar.bottomAnchor, constant: -22)])
        [headingRow, newButton, listScroll, footer].forEach { $0.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        window.acceptsMouseMovedEvents = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            let point = self.background.convert(event.locationInWindow, from: nil)
            if event.type == .mouseMoved {
                if point.x <= 12 { self.showSidebar() }
                else if point.x > Theme.sidebarWidth + 24 { self.hideSidebar() }
            } else if point.x > Theme.sidebarWidth { self.hideSidebar() }
            return event
        }
    }
    func showSidebar() {
        guard sidebar.isHidden else { return }
        sidebar.isHidden = false
    }
    func setupHUD() {
        hud.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(hud)
        NSLayoutConstraint.activate([
            hud.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            hud.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -22)
        ])
        hudFadeTimer = Timer.scheduledTimer(withTimeInterval: 2.4, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.hud.alphaValue > 0.02 else { return }
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.7
                    self.hud.animator().alphaValue = 0
                }
            }
        }
        window.acceptsMouseMovedEvents = true
        let tracker = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .keyDown]) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            self.revealHUD()
            return event
        }
        hudRevealMonitor = tracker
    }
    func revealHUD() {
        guard !hud.isHidden else { return }
        hud.alphaValue = 1
    }
    func refreshHUD() {
        let words = editor.string.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        hud.update(words: words, saved: !currentNoteDirty)
    }
    @objc func hideSidebar() { sidebar.isHidden = true }
    @objc func toggleSidebar() { sidebar.isHidden.toggle() }
    @objc func toggleImmersive() {
        immersive.toggle()
        if immersive {
            window.styleMask = [.borderless, .resizable]
            window.setFrame((window.screen ?? NSScreen.main)!.frame, display: true)
            NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar]
        } else {
            NSApp.presentationOptions = []
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setFrame(NSRect(x: 100, y: 100, width: 1100, height: 760), display: true); window.center()
        }
        window.makeFirstResponder(editor)
    }
    func windowDidResize(_ notification: Notification) {
        editor.textContainerInset = NSSize(width: 0, height: 0)
        let width = scroll.contentSize.width
        if width > 0 {
            editor.setFrameSize(NSSize(width: width, height: max(editor.frame.height, scroll.contentSize.height)))
            editor.textContainer?.containerSize = NSSize(width: max(1, width), height: CGFloat.greatestFiniteMagnitude)
        }
        scroll.contentView.scroll(to: NSPoint(x: 0, y: scroll.contentView.bounds.origin.y))
        background.needsDisplay = true
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        if immersive { NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar] }
    }
    func applicationDidResignActive(_ notification: Notification) { NSApp.presentationOptions = [] }
    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        window = FocusWindow(contentRect: (NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)), styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
        window.title = "Kodmoz Writer"; window.titleVisibility = .hidden; window.titlebarAppearsTransparent = true
        window.collectionBehavior = [.fullScreenPrimary]; window.delegate = self
        window.contentView = background
        background.autoresizingMask = [.width, .height]
        scroll.contentView = WritingClipView()
        scroll.contentView.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.drawsBackground = false; scroll.borderType = .noBorder; scroll.hasVerticalScroller = false
        editor.drawsBackground = false; editor.isRichText = true; editor.allowsUndo = true
        editor.isAutomaticQuoteSubstitutionEnabled = true; editor.isAutomaticSpellingCorrectionEnabled = false
        editor.isHorizontallyResizable = false; editor.isVerticallyResizable = true
        editor.autoresizingMask = [.width]
        editor.setFrameSize(NSSize(width: 800, height: 600))
        editor.minSize = NSSize(width: 0, height: 600); editor.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        editor.textContainer?.widthTracksTextView = true
        editor.textContainerInset = NSSize(width: 0, height: 0)
        editor.textContainer?.lineFragmentPadding = 0
        editor.font = Theme.writingFont(); editor.delegate = self
        scroll.documentView = editor
        background.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.centerXAnchor.constraint(equalTo: background.centerXAnchor),
            scroll.widthAnchor.constraint(lessThanOrEqualTo: background.widthAnchor, multiplier: 0.88),
            scroll.widthAnchor.constraint(equalToConstant: Theme.columnWidth).withPriority(.defaultHigh),
            scroll.bottomAnchor.constraint(equalTo: background.bottomAnchor),
            scroll.topAnchor.constraint(equalTo: background.topAnchor, constant: 96),
        ])
        setupSidebar()
        setupHUD()
        loadNotes()
        let kind = defaults.string(forKey: "kind") ?? "color"
        if kind == "scene" { setScene(defaults.integer(forKey: "scene")) }
        else if kind == "customImage", let data = try? Data(contentsOf: saveURL.deletingLastPathComponent().appendingPathComponent("Background.image")), let image = NSImage(data: data) { applyImage(image) }
        else if let data = defaults.data(forKey: "color"), let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) { applyColor(color) }
        else { applyColor(palettes[0].color) }
        window.setFrame((window.screen ?? NSScreen.main)!.frame, display: true)
        window.makeKeyAndOrderFront(nil); window.makeFirstResponder(editor)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar]
        windowDidResize(Notification(name: NSWindow.didResizeNotification))
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot"), CommandLine.arguments.count > index + 1 {
            runSnapshotMode(CommandLine.arguments[index + 1])
        }
    }
    func runSnapshotMode(_ directory: String) {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        snapshotView(background, to: directory + "/writing.png")
        showSidebar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [self] in
            snapshotView(background, to: directory + "/sidebar.png")
            showSettings()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                if let content = settings?.contentView { content.displayIfNeeded(); snapshotView(content, to: directory + "/settings.png") }
                closeSettings()
                addLink()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                    if let content = linkSheet?.contentView { content.displayIfNeeded(); snapshotView(content, to: directory + "/link.png") }
                    linkSheet?.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { NSApp.terminate(nil) }
                }
            }
        }
    }
    func snapshotView(_ view: NSView, to path: String) {
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: URL(fileURLWithPath: path))
    }
    func buildMenu() {
        let menu = NSMenu()
        func section(_ name: String) -> NSMenu {
            let item = NSMenuItem(); item.title = name; let sub = NSMenu(title: name); item.submenu = sub; menu.addItem(item); return sub
        }
        func add(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String, _ target: AnyObject? = nil) {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key); item.target = target; menu.addItem(item)
        }
        let app = section("Kodmoz Writer")
        add(app, "Görünüm ve Arka Plan…", #selector(showSettings), ",", self)
        app.addItem(.separator()); add(app, "Kodmoz Writer’dan Çık", #selector(NSApplication.terminate(_:)), "q")
        let file = section("Dosya")
        add(file, "Yeni Yazı", #selector(newNote), "n", self)
        add(file, "RTF Olarak Dışa Aktar…", #selector(exportDocument), "s", self)
        let edit = section("Düzen")
        add(edit, "Geri Al", Selector(("undo:")), "z"); add(edit, "Yinele", Selector(("redo:")), "Z")
        edit.addItem(.separator())
        add(edit, "Kes", #selector(NSText.cut(_:)), "x"); add(edit, "Kopyala", #selector(NSText.copy(_:)), "c"); add(edit, "Yapıştır", #selector(NSText.paste(_:)), "v"); add(edit, "Tümünü Seç", #selector(NSText.selectAll(_:)), "a")
        let format = section("Biçim")
        add(format, "Bağlantı Ekle…", #selector(addLink), "l", self)
        add(format, "Kalın", #selector(bold), "b", self); add(format, "İtalik", #selector(italic), "i", self)
        add(format, "Altı Çizili", #selector(NSTextView.underline(_:)), "u")
        add(format, "Yazı Tipi…", #selector(NSFontManager.orderFrontFontPanel(_:)), "t", NSFontManager.shared)
        let view = section("Görünüm")
        add(view, "Tam Ekran", #selector(toggleImmersive), "f", self)
        view.items.last?.keyEquivalentModifierMask = [.command, .control]
        add(view, "Yazılarım", #selector(toggleSidebar), "L", self)
        NSApp.mainMenu = menu
    }
    @objc func addLink() {
        if let sheet = linkSheet, sheet.isVisible { return }
        linkSheet = nil
        let range = editor.selectedRange()
        let selected = (editor.string as NSString).substring(with: range)
        let existing = range.location < editor.string.utf16.count ? editor.textStorage?.attribute(.link, at: range.location, effectiveRange: nil) : nil
        let sheet = LinkSheet(selectedText: selected, existingURL: existing.map { String(describing: $0) })
        sheet.onDismiss = { [weak self] in self?.linkSheet = nil }
        sheet.onSubmit = { [weak self] title, url in
            guard let self else { return }
            self.insertLink(title: title, url: url, in: range, selected: selected)
        }
        sheet.onRemove = { [weak self] in
            guard let self else { return }
            guard range.length > 0, self.editor.shouldChangeText(in: range, replacementString: nil) else { return }
            self.editor.textStorage?.removeAttribute(.link, range: range)
            self.editor.didChangeText()
            self.window.makeFirstResponder(self.editor)
        }
        linkSheet = sheet
        sheet.present(in: window)
    }
    private func insertLink(title: String, url: URL, in range: NSRange, selected: String) {
        let replacement: NSMutableAttributedString
        if range.length > 0 && title == selected, let storage = editor.textStorage {
            replacement = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
        } else {
            var attributes = editor.typingAttributes
            attributes[.font] = attributes[.font] ?? Theme.writingFont()
            replacement = NSMutableAttributedString(string: title, attributes: attributes)
        }
        replacement.addAttribute(.link, value: url, range: NSRange(location: 0, length: replacement.length))
        guard editor.shouldChangeText(in: range, replacementString: title) else { return }
        editor.textStorage?.replaceCharacters(in: range, with: replacement)
        editor.didChangeText()
        editor.setSelectedRange(NSRange(location: range.location + replacement.length, length: 0))
        var attributes = editor.typingAttributes
        attributes.removeValue(forKey: .link)
        editor.typingAttributes = attributes
        window.makeFirstResponder(editor)
    }
    @objc func bold() { toggleTrait(.boldFontMask) }
    @objc func italic() { toggleTrait(.italicFontMask) }
    func toggleTrait(_ trait: NSFontTraitMask) {
        let range = editor.selectedRange()
        let manager = NSFontManager.shared
        let font = (range.length > 0 ? editor.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont : editor.typingAttributes[.font] as? NSFont) ?? Theme.writingFont()
        let remove = manager.traits(of: font).contains(trait)
        if range.length == 0 {
            var attrs = editor.typingAttributes
            attrs[.font] = remove ? manager.convert(font, toNotHaveTrait: trait) : manager.convert(font, toHaveTrait: trait)
            editor.typingAttributes = attrs
        } else {
            let changed = NSMutableAttributedString(attributedString: editor.textStorage!.attributedSubstring(from: range))
            changed.enumerateAttribute(.font, in: NSRange(location: 0, length: changed.length)) { value, subrange, _ in
                let current = value as? NSFont ?? font
                changed.addAttribute(.font, value: remove ? manager.convert(current, toNotHaveTrait: trait) : manager.convert(current, toHaveTrait: trait), range: subrange)
            }
            if editor.shouldChangeText(in: range, replacementString: nil) {
                editor.textStorage?.replaceCharacters(in: range, with: changed); editor.didChangeText()
                editor.setSelectedRange(NSRange(location: range.location, length: changed.length))
            }
        }
    }
    func applyColor(_ color: NSColor) {
        background.picture = nil; background.color = color; background.needsDisplay = true
        let rgb = color.usingColorSpace(.sRGB) ?? .black
        func linear(_ v: CGFloat) -> CGFloat { v <= 0.04045 ? v/12.92 : pow((v+0.055)/1.055, 2.4) }
        let luminance = 0.2126*linear(rgb.redComponent)+0.7152*linear(rgb.greenComponent)+0.0722*linear(rgb.blueComponent)
        ink = luminance > 0.179 ? .black : .white; updateInk()
    }
    func applyImage(_ image: NSImage) { background.picture = image; background.needsDisplay = true; ink = .white; updateInk() }
    func updateInk() {
        editor.textStorage?.addAttribute(.foregroundColor, value: ink, range: NSRange(location: 0, length: editor.string.utf16.count))
        editor.insertionPointColor = ink
        editor.linkTextAttributes = [
            .foregroundColor: ink,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: ink.withAlphaComponent(0.4)
        ]
        var attrs = editor.typingAttributes; attrs[.foregroundColor] = ink
        if attrs[.font] == nil { attrs[.font] = Theme.writingFont() }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = Theme.writingSize * 0.72
        paragraph.paragraphSpacing = Theme.writingSize * 0.55
        attrs[.paragraphStyle] = paragraph; editor.typingAttributes = attrs
        refreshHUD()
    }
    func setScene(_ index: Int) { let index = min(max(index, 0), 9); applyImage(landscape(index)); defaults.set("scene", forKey: "kind"); defaults.set(index, forKey: "scene") }
    @objc func choosePalette(_ sender: NSButton) {
        let color = palettes[sender.tag].color; applyColor(color); persistColor(color)
    }
    func persistColor(_ color: NSColor) { defaults.set("color", forKey: "kind"); defaults.set(try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true), forKey: "color") }
    @objc func chooseScene(_ sender: NSButton) { setScene(sender.tag) }
    @objc func customColor() {
        let panel = NSColorPanel.shared; panel.color = background.color; panel.setTarget(self); panel.setAction(#selector(colorChanged)); panel.makeKeyAndOrderFront(nil)
    }
    @objc func colorChanged(_ sender: NSColorPanel) { applyColor(sender.color); persistColor(sender.color) }
    @objc func customImage() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.image]; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: settings ?? window) { response in
            guard response == .OK, let url = panel.url, let image = NSImage(contentsOf: url), let data = try? Data(contentsOf: url) else { return }
            do { try data.write(to: self.saveURL.deletingLastPathComponent().appendingPathComponent("Background.image"), options: .atomic); self.defaults.set("customImage", forKey: "kind"); self.applyImage(image) }
            catch { self.showError(error) }
        }
    }
    @objc func showSettings() {
        if let settings {
            settings.makeKeyAndOrderFront(nil)
            syncSettingsSelection()
            return
        }
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 720, height: 620), styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.title = "Görünüm"
        [.closeButton, .miniaturizeButton, .zoomButton].forEach { panel.standardWindowButton($0)?.isHidden = true }
        let background = CardBackground()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.appearance = NSAppearance(named: .darkAqua)
        background.wantsLayer = true
        background.layer?.cornerRadius = 16
        background.layer?.masksToBounds = true
        panel.contentView = background

        let eyebrow = NSTextField(labelWithAttributedString: NSAttributedString(string: "GÖRÜNÜM", attributes: Theme.tracking(9)))
        let heading = NSTextField(labelWithString: "Atmosfer")
        heading.font = Theme.writingFont(28)
        heading.textColor = NSColor.white.withAlphaComponent(0.96)
        let subtitle = NSTextField(wrappingLabelWithString: "Yazı alanının arkasındaki renk, manzara veya kendi görselin. Her seçim anında kaydedilir.")
        subtitle.font = .systemFont(ofSize: 11.5)
        subtitle.textColor = NSColor.white.withAlphaComponent(0.48)
        subtitle.preferredMaxLayoutWidth = 664

        func caption(_ text: String) -> NSTextField {
            NSTextField(labelWithAttributedString: NSAttributedString(string: text, attributes: [
                .font: NSFont.systemFont(ofSize: 9.5, weight: .semibold),
                .kern: 1.2,
                .foregroundColor: NSColor.white.withAlphaComponent(0.42)
            ]))
        }

        swatches = palettes.enumerated().map { index, palette in
            SwatchButton(palette: palette, index: index, target: self, action: #selector(choosePalette(_:)))
        }
        let colorColumns = stride(from: 0, to: swatches.count, by: 5).map { start -> NSStackView in
            let column = NSStackView(views: Array(swatches[start..<min(start + 5, swatches.count)]))
            column.orientation = .vertical
            column.alignment = .leading
            column.spacing = 2
            column.arrangedSubviews.forEach { $0.widthAnchor.constraint(equalTo: column.widthAnchor).isActive = true }
            return column
        }
        let colorGrid = NSStackView(views: colorColumns)
        colorGrid.orientation = .horizontal
        colorGrid.distribution = .fillEqually
        colorGrid.alignment = .top
        colorGrid.spacing = 12

        sceneTiles = (0..<sceneNames.count).map { index in
            SceneTile(index: index, name: sceneNames[index], image: landscape(index), target: self, action: #selector(chooseScene(_:)))
        }
        let sceneRows = stride(from: 0, to: sceneTiles.count, by: 5).map { start -> NSStackView in
            let row = NSStackView(views: Array(sceneTiles[start..<min(start + 5, sceneTiles.count)]))
            row.orientation = .horizontal
            row.distribution = .fillEqually
            row.spacing = 8
            return row
        }
        let sceneGrid = NSStackView(views: sceneRows)
        sceneGrid.orientation = .vertical
        sceneGrid.alignment = .leading
        sceneGrid.spacing = 8
        sceneRows.forEach { $0.widthAnchor.constraint(equalTo: sceneGrid.widthAnchor).isActive = true }

        let customColorButton = GhostButton(title: "Özel renk…", symbol: "eyedropper", action: #selector(customColor), target: self)
        let customImageButton = GhostButton(title: "Görsel seç…", symbol: "photo", action: #selector(customImage), target: self)
        customColorButton.widthAnchor.constraint(equalToConstant: 132).isActive = true
        customImageButton.widthAnchor.constraint(equalToConstant: 132).isActive = true
        let customRow = NSStackView(views: [customColorButton, customImageButton, NSView()])
        customRow.orientation = .horizontal
        customRow.spacing = 8

        let status = NSTextField(labelWithAttributedString: NSAttributedString(string: "", attributes: [
            .font: NSFont.systemFont(ofSize: 10.5, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.40)
        ]))
        settingsStatusLabel = status

        let shortcuts = NSTextField(labelWithString: "⌘L Bağlantı   ·   ⌘B Kalın   ·   ⌘I İtalik   ·   ⌘U Altı çizili   ·   ⌘T Yazı tipi   ·   ⌘N Yeni yazı   ·   ⇧⌘L Menü")
        shortcuts.font = .systemFont(ofSize: 10.5)
        shortcuts.textColor = NSColor.white.withAlphaComponent(0.34)

        let footer = NSStackView(views: [status, NSView(), shortcuts])
        footer.orientation = .horizontal
        footer.spacing = 8

        let colorsCaption = caption("RENKLER")
        let scenesCaption = caption("MANZARALAR")
        let stack = NSStackView(views: [eyebrow, heading, subtitle, colorsCaption, colorGrid, customRow, scenesCaption, sceneGrid, footer])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.setCustomSpacing(5, after: eyebrow)
        stack.setCustomSpacing(6, after: heading)
        stack.setCustomSpacing(20, after: subtitle)
        stack.setCustomSpacing(7, after: colorsCaption)
        stack.setCustomSpacing(10, after: colorGrid)
        stack.setCustomSpacing(18, after: customRow)
        stack.setCustomSpacing(7, after: scenesCaption)
        stack.setCustomSpacing(18, after: sceneGrid)
        stack.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: background.topAnchor, constant: 30),
            stack.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -22)
        ])
        [colorGrid, customRow, sceneGrid, footer].forEach { $0.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        let close = GhostButton(title: "Kapat", action: #selector(closeSettings), target: self)
        close.widthAnchor.constraint(equalToConstant: 78).isActive = true
        let closeRow = NSStackView(views: [NSView(), close])
        closeRow.orientation = .horizontal
        stack.addArrangedSubview(closeRow)

        settings = panel
        window.addChildWindow(panel, ordered: .above)
        panel.setContentSize(NSSize(width: 720, height: stack.fittingSize.height + 52))
        panel.center()
        syncSettingsSelection()
        panel.makeKeyAndOrderFront(nil)
    }
    @objc func closeSettings() { settings?.orderOut(nil) }
    func currentPaletteIndex() -> Int? {
        let stored = defaults.data(forKey: "color").flatMap { try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: $0) }
        guard defaults.string(forKey: "kind") == "color", let stored else { return nil }
        return palettes.firstIndex { palette in
            guard let a = palette.color.usingColorSpace(.sRGB), let b = stored.usingColorSpace(.sRGB) else { return false }
            return abs(a.redComponent - b.redComponent) < 0.004 && abs(a.greenComponent - b.greenComponent) < 0.004 && abs(a.blueComponent - b.blueComponent) < 0.004
        }
    }
    func syncSettingsSelection() {
        let paletteIndex = currentPaletteIndex()
        let sceneIndex = defaults.string(forKey: "kind") == "scene" ? defaults.integer(forKey: "scene") : nil
        for swatch in swatches { swatch.isActive = swatch.tag == paletteIndex }
        for tile in sceneTiles { tile.isActive = tile.tag == sceneIndex }
        let kind = defaults.string(forKey: "kind") ?? "color"
        let label: String
        switch kind {
        case "scene": label = "Manzara · \(sceneNames[min(max(defaults.integer(forKey: "scene"), 0), sceneNames.count - 1)])"
        case "customImage": label = "Kendi görselin"
        default:
            if let paletteIndex { label = "Renk · \(palettes[paletteIndex].name)" } else { label = "Özel renk" }
        }
        settingsStatusLabel?.stringValue = label
        settingsStatusLabel?.alphaValue = 0.9
    }
    func textDidChange(_ notification: Notification) {
        guard !loadingNote else { return }
        currentNoteDirty = true
        refreshHUD()
        if saveCurrentNote() { rebuildNotes(); refreshHUD() }
    }
    @discardableResult
    func saveCurrentNote() -> Bool {
        guard !currentNoteID.isEmpty, currentNoteDirty else { return true }
        guard let data = editor.rtf(from: NSRange(location: 0, length: editor.string.utf16.count)) else { return false }
        do {
            try data.write(to: noteURL(currentNoteID), options: .atomic)
            ensureDates(currentNoteID)
            noteDates[currentNoteID]?.updatedAt = Date()
            try persistDates()
            currentNoteDirty = false
            return true
        }
        catch { showError(error); return false }
    }
    func saveDraft() { _ = saveCurrentNote() }
    func showError(_ error: Error) {
        guard !isShowingSaveError else { return }
        isShowingSaveError = true
        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: window) { _ in self.isShowingSaveError = false }
    }
    @objc func exportDocument() {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.rtf]; panel.nameFieldStringValue = "Yazım.rtf"
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url, let data = self.editor.rtf(from: NSRange(location: 0, length: self.editor.string.utf16.count)) else { return }
            do { try data.write(to: url, options: .atomic) } catch { self.showError(error) }
        }
    }
    func windowWillClose(_ notification: Notification) { if notification.object as? NSWindow === window { saveDraft(); NSApp.terminate(nil) } }
    func applicationWillTerminate(_ notification: Notification) { saveDraft() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
extension NSLayoutConstraint {
    func withPriority(_ priority: NSLayoutConstraint.Priority) -> NSLayoutConstraint { self.priority = priority; return self }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.regular)
app.delegate = delegate
if CommandLine.arguments.contains("--self-test") {
    delegate.editor.textStorage?.setAttributedString(NSAttributedString(string: "Odaklan. Yaz.\nTürkçe: ıİşŞğĞçÇöÖüÜ", attributes: [.font: NSFont.systemFont(ofSize: 24)]))
    delegate.editor.setSelectedRange(NSRange(location: 0, length: 7))
    delegate.bold()
    let boldFont = delegate.editor.textStorage!.attribute(.font, at: 0, effectiveRange: nil) as! NSFont
    precondition(NSFontManager.shared.traits(of: boldFont).contains(.boldFontMask))
    delegate.italic()
    let both = delegate.editor.textStorage!.attribute(.font, at: 0, effectiveRange: nil) as! NSFont
    precondition(NSFontManager.shared.traits(of: both).contains([.boldFontMask, .italicFontMask]))
    delegate.bold()
    let italicOnly = delegate.editor.textStorage!.attribute(.font, at: 0, effectiveRange: nil) as! NSFont
    precondition(!NSFontManager.shared.traits(of: italicOnly).contains(.boldFontMask))
    precondition(NSFontManager.shared.traits(of: italicOnly).contains(.italicFontMask))
    for palette in palettes { delegate.applyColor(palette.color) }
    delegate.applyColor(.white); precondition(delegate.ink == .black)
    delegate.applyColor(.black); precondition(delegate.ink == .white)
    for index in 0..<10 { precondition(landscape(index).tiffRepresentation != nil) }
    let data = delegate.editor.rtf(from: NSRange(location: 0, length: delegate.editor.string.utf16.count))!
    let restored = NSAttributedString(rtf: data, documentAttributes: nil)!
    precondition(restored.string == delegate.editor.string)
    print("PASS: formatting toggles, 10 palettes, contrast, 10 rendered landscapes, Turkish RTF round-trip")
} else {
    app.run()
}
