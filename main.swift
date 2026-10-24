import AppKit

struct Palette {
    let name: String
    let color: NSColor
}
let palettes: [Palette] = [
    .init(name: "Gece", color: NSColor(srgbRed: 0.07, green: 0.09, blue: 0.13, alpha: 1)),
    .init(name: "Kâğıt", color: NSColor(srgbRed: 0.96, green: 0.94, blue: 0.88, alpha: 1)),
    .init(name: "Orman", color: NSColor(srgbRed: 0.10, green: 0.20, blue: 0.17, alpha: 1)),
    .init(name: "Okyanus", color: NSColor(srgbRed: 0.09, green: 0.19, blue: 0.29, alpha: 1)),
    .init(name: "Lavanta", color: NSColor(srgbRed: 0.84, green: 0.81, blue: 0.91, alpha: 1)),
    .init(name: "Kum", color: NSColor(srgbRed: 0.86, green: 0.77, blue: 0.63, alpha: 1)),
    .init(name: "Gül", color: NSColor(srgbRed: 0.93, green: 0.82, blue: 0.81, alpha: 1)),
    .init(name: "Kömür", color: NSColor(srgbRed: 0.16, green: 0.16, blue: 0.17, alpha: 1)),
    .init(name: "Adaçayı", color: NSColor(srgbRed: 0.75, green: 0.82, blue: 0.73, alpha: 1)),
    .init(name: "Beyaz", color: .white)
]
let sceneNames = ["Sisli Dağlar", "Gün Batımı", "Çam Ormanı", "Kum Tepeleri", "Gece Göğü", "Sakin Deniz", "Lavanta Tepeleri", "Karlı Zirveler", "Sonbahar", "Ay Işığı"]

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
final class Background: NSView {
    var picture: NSImage?
    var color: NSColor = palettes[0].color
    override func draw(_ dirtyRect: NSRect) {
        color.setFill(); bounds.fill()
        if let picture {
            let scale = max(bounds.width / picture.size.width, bounds.height / picture.size.height)
            let size = NSSize(width: picture.size.width * scale, height: picture.size.height * scale)
            picture.draw(in: NSRect(x: (bounds.width-size.width)/2, y: (bounds.height-size.height)/2, width: size.width, height: size.height))
            NSColor.black.withAlphaComponent(0.60).setFill(); bounds.fill()
        }
    }
}

@MainActor
func landscape(_ index: Int) -> NSImage {
    let size = NSSize(width: 1920, height: 1200)
    return NSImage(size: size, flipped: false) { rect in
        let skies: [(NSColor, NSColor)] = [
            (.init(srgbRed: 0.29, green: 0.43, blue: 0.48, alpha: 1), .init(srgbRed: 0.70, green: 0.77, blue: 0.74, alpha: 1)),
            (.init(srgbRed: 0.27, green: 0.20, blue: 0.40, alpha: 1), .init(srgbRed: 0.94, green: 0.53, blue: 0.36, alpha: 1)),
            (.init(srgbRed: 0.12, green: 0.27, blue: 0.26, alpha: 1), .init(srgbRed: 0.53, green: 0.65, blue: 0.54, alpha: 1)),
            (.init(srgbRed: 0.38, green: 0.49, blue: 0.56, alpha: 1), .init(srgbRed: 0.91, green: 0.75, blue: 0.54, alpha: 1)),
            (.init(srgbRed: 0.025, green: 0.04, blue: 0.12, alpha: 1), .init(srgbRed: 0.16, green: 0.13, blue: 0.30, alpha: 1)),
            (.init(srgbRed: 0.23, green: 0.47, blue: 0.59, alpha: 1), .init(srgbRed: 0.73, green: 0.82, blue: 0.80, alpha: 1)),
            (.init(srgbRed: 0.34, green: 0.30, blue: 0.53, alpha: 1), .init(srgbRed: 0.77, green: 0.64, blue: 0.75, alpha: 1)),
            (.init(srgbRed: 0.22, green: 0.39, blue: 0.55, alpha: 1), .init(srgbRed: 0.79, green: 0.86, blue: 0.88, alpha: 1)),
            (.init(srgbRed: 0.32, green: 0.33, blue: 0.29, alpha: 1), .init(srgbRed: 0.86, green: 0.65, blue: 0.40, alpha: 1)),
            (.init(srgbRed: 0.04, green: 0.09, blue: 0.19, alpha: 1), .init(srgbRed: 0.26, green: 0.37, blue: 0.46, alpha: 1))
        ]
        NSGradient(starting: skies[index].1, ending: skies[index].0)!.draw(in: rect, angle: 90)
        if [1, 4, 9].contains(index) {
            NSColor(srgbRed: 1, green: 0.88, blue: 0.68, alpha: 0.85).setFill()
            NSBezierPath(ovalIn: NSRect(x: 1390, y: 750, width: index == 1 ? 170 : 85, height: index == 1 ? 170 : 85)).fill()
        }
        if index == 4 || index == 9 {
            for i in 0..<160 {
                let x = CGFloat((i * 7919 + 41) % 1920), y = CGFloat((i * 3571 + 500) % 1200)
                NSColor.white.withAlphaComponent(0.25 + Double(i % 6) * 0.1).setFill()
                NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 2, height: 2)).fill()
            }
        }
        for layer in 0..<5 {
            let path = NSBezierPath(); path.move(to: .zero)
            let base = CGFloat(470 - layer * 80)
            path.line(to: NSPoint(x: 0, y: base))
            for step in 0...24 {
                let x = CGFloat(step) * 80
                let wave = sin(Double(step) * 0.43 + Double(layer) * 1.7 + Double(index))
                let height = CGFloat(wave) * CGFloat(index == 3 || index == 5 ? 55 : 150)
                path.line(to: NSPoint(x: x, y: base + height))
            }
            path.line(to: NSPoint(x: 1920, y: 0)); path.close()
            let tint: NSColor
            if index == 3 { tint = NSColor(srgbRed: 0.72-Double(layer)*0.07, green: 0.51-Double(layer)*0.05, blue: 0.31-Double(layer)*0.03, alpha: 1) }
            else if index == 6 { tint = NSColor(srgbRed: 0.41-Double(layer)*0.05, green: 0.32-Double(layer)*0.04, blue: 0.52-Double(layer)*0.05, alpha: 1) }
            else if index == 8 { tint = NSColor(srgbRed: 0.49-Double(layer)*0.07, green: 0.29-Double(layer)*0.04, blue: 0.16-Double(layer)*0.02, alpha: 1) }
            else if index == 7 { tint = NSColor(white: 0.80-Double(layer)*0.12, alpha: 1) }
            else { tint = NSColor(srgbRed: 0.23-Double(layer)*0.04, green: 0.36-Double(layer)*0.05, blue: 0.39-Double(layer)*0.05, alpha: 1) }
            tint.setFill(); path.fill()
        }
        if index == 2 || index == 8 {
            for i in 0..<42 {
                let x = CGFloat(i * 49), h = CGFloat(140 + (i * 73) % 230)
                let tree = NSBezierPath(); tree.move(to: NSPoint(x: x, y: 75)); tree.line(to: NSPoint(x: x + 65, y: 75+h)); tree.line(to: NSPoint(x: x+130, y: 75)); tree.close()
                NSColor(srgbRed: 0.045, green: 0.13, blue: 0.11, alpha: 0.8).setFill(); tree.fill()
            }
        }
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
    var ink: NSColor = .white
    let sidebar = NSVisualEffectView()
    let noteList = NSStackView()
    var noteIDs: [String] = []
    var currentNoteID = ""
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
            noteIDs = try FileManager.default.contentsOfDirectory(at: notesFolder, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "rtf" }
                .sorted { ((try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast) > ((try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast) }
                .map { $0.deletingPathExtension().lastPathComponent }
            if noteIDs.isEmpty {
                let id = UUID().uuidString
                // Preserve the original draft and migrate a copy.
                if FileManager.default.fileExists(atPath: saveURL.path) {
                    try FileManager.default.copyItem(at: saveURL, to: noteURL(id))
                } else {
                    let data = NSAttributedString(string: "").rtf(from: NSRange(location: 0, length: 0), documentAttributes: [:])!
                    try data.write(to: noteURL(id), options: .atomic)
                }
                noteIDs = [id]
            }
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
            currentNoteID = id; defaults.set(id, forKey: "activeNote")
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
            let data = NSAttributedString(string: "", attributes: [.font: NSFont.systemFont(ofSize: 24)]).rtf(from: NSRange(location: 0, length: 0), documentAttributes: [:])!
            try data.write(to: noteURL(id), options: .atomic)
            noteIDs.insert(id, at: 0); openNote(id, savingCurrent: false)
        } catch { showError(error) }
    }
    @objc func selectNote(_ sender: NSButton) { openNote(noteIDs[sender.tag]) }
    func titleForNote(_ id: String) -> String {
        let text: String
        if id == currentNoteID { text = editor.string }
        else { text = (try? Data(contentsOf: noteURL(id))).flatMap { NSAttributedString(rtf: $0, documentAttributes: nil)?.string } ?? "" }
        let title = text.split(whereSeparator: { $0.isNewline }).first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? ""
        return title.isEmpty ? "Yeni yazı" : String(title.prefix(48))
    }
    func rebuildNotes() {
        for view in noteList.arrangedSubviews { noteList.removeArrangedSubview(view); view.removeFromSuperview() }
        for (i, id) in noteIDs.enumerated() {
            let button = NSButton(title: (id == currentNoteID ? "●  " : "    ") + titleForNote(id), target: self, action: #selector(selectNote))
            button.tag = i; button.alignment = .left; button.bezelStyle = .recessed
            button.font = .systemFont(ofSize: 14); button.lineBreakMode = .byTruncatingTail
            button.heightAnchor.constraint(equalToConstant: 38).isActive = true
            noteList.addArrangedSubview(button)
        }
    }
    func setupSidebar() {
        sidebar.material = .sidebar; sidebar.blendingMode = .withinWindow; sidebar.state = .active
        sidebar.isHidden = true; sidebar.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(sidebar)
        NSLayoutConstraint.activate([sidebar.leadingAnchor.constraint(equalTo: background.leadingAnchor), sidebar.topAnchor.constraint(equalTo: background.topAnchor), sidebar.bottomAnchor.constraint(equalTo: background.bottomAnchor), sidebar.widthAnchor.constraint(equalToConstant: 280)])
        let header = NSTextField(labelWithString: "Yazılarım"); header.font = .systemFont(ofSize: 22, weight: .semibold)
        let newButton = NSButton(title: "+  Yeni yazı", target: self, action: #selector(newNote))
        let appearance = NSButton(title: "Görünüm ve arka plan…", target: self, action: #selector(showSettings))
        let hide = NSButton(title: "Menüyü gizle  ‹", target: self, action: #selector(hideSidebar))
        let listScroll = NSScrollView(); listScroll.drawsBackground = false; listScroll.hasVerticalScroller = true; listScroll.autohidesScrollers = true
        noteList.orientation = .vertical; noteList.alignment = .width; noteList.spacing = 6
        noteList.translatesAutoresizingMaskIntoConstraints = false; listScroll.documentView = noteList
        NSLayoutConstraint.activate([noteList.widthAnchor.constraint(equalTo: listScroll.contentView.widthAnchor)])
        let stack = NSStackView(views: [header, newButton, listScroll, appearance, hide]); stack.orientation = .vertical; stack.alignment = .width; stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false; sidebar.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: -20), stack.topAnchor.constraint(equalTo: sidebar.topAnchor, constant: 55), stack.bottomAnchor.constraint(equalTo: sidebar.bottomAnchor, constant: -30)])
        window.acceptsMouseMovedEvents = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            let point = self.background.convert(event.locationInWindow, from: nil)
            if event.type == .mouseMoved {
                if point.x <= 14 { self.sidebar.isHidden = false }
                else if point.x > 300 { self.hideSidebar() }
            } else if point.x > 280 { self.hideSidebar() }
            return event
        }
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
        editor.textContainerInset = NSSize(width: 32, height: 48)
        let width = scroll.contentSize.width
        if width > 0 {
            editor.setFrameSize(NSSize(width: width, height: max(editor.frame.height, scroll.contentSize.height)))
            editor.textContainer?.containerSize = NSSize(width: max(1, width - 64), height: CGFloat.greatestFiniteMagnitude)
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
        editor.textContainerInset = NSSize(width: 32, height: 48)
        editor.textContainer?.lineFragmentPadding = 12
        editor.font = .systemFont(ofSize: 24); editor.delegate = self
        scroll.documentView = editor
        background.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.centerXAnchor.constraint(equalTo: background.centerXAnchor),
            scroll.widthAnchor.constraint(lessThanOrEqualTo: background.widthAnchor, multiplier: 0.84),
            scroll.widthAnchor.constraint(equalToConstant: 860).withPriority(.defaultHigh),
            scroll.topAnchor.constraint(equalTo: background.topAnchor), scroll.bottomAnchor.constraint(equalTo: background.bottomAnchor)
        ])
        setupSidebar()
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
        let range = editor.selectedRange()
        let selected = (editor.string as NSString).substring(with: range)
        let existing = range.location < editor.string.utf16.count ? editor.textStorage?.attribute(.link, at: range.location, effectiveRange: nil) : nil
        let alert = NSAlert()
        alert.messageText = "Bağlantı ekle"
        alert.informativeText = "Bağlantı metnini ve adresini gir. Açmak için ⌘ tuşuyla tıkla."
        alert.addButton(withTitle: "Ekle"); alert.addButton(withTitle: "İptal")
        if existing != nil { alert.addButton(withTitle: "Bağlantıyı kaldır") }
        let text = NSTextField(string: selected); text.placeholderString = "Bağlantı metni"; text.setAccessibilityLabel("Bağlantı metni")
        let address = NSTextField(string: existing.map { String(describing: $0) } ?? "")
        address.placeholderString = "https://ornek.com"; address.setAccessibilityLabel("Bağlantı adresi")
        let form = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 156))
        let textLabel = NSTextField(labelWithString: "Metin")
        textLabel.frame = NSRect(x: 0, y: 132, width: 420, height: 20)
        text.frame = NSRect(x: 0, y: 96, width: 420, height: 30)
        let addressLabel = NSTextField(labelWithString: "Adres")
        addressLabel.frame = NSRect(x: 0, y: 62, width: 420, height: 20)
        address.frame = NSRect(x: 0, y: 26, width: 420, height: 30)
        for field in [text, address] {
            field.font = .systemFont(ofSize: 14)
            field.isBezeled = true; field.isBordered = true
            field.isEditable = true; field.isSelectable = true
            field.cell?.isScrollable = true
            field.autoresizingMask = [.width]
        }
        textLabel.autoresizingMask = [.width]; addressLabel.autoresizingMask = [.width]
        [textLabel, text, addressLabel, address].forEach { form.addSubview($0) }
        text.nextKeyView = address
        alert.accessoryView = form
        alert.window.initialFirstResponder = selected.isEmpty ? text : address
        alert.beginSheetModal(for: window) { response in
            if response == .alertThirdButtonReturn {
                guard range.length > 0, self.editor.shouldChangeText(in: range, replacementString: nil) else { return }
                self.editor.textStorage?.removeAttribute(.link, range: range)
                self.editor.didChangeText(); self.window.makeFirstResponder(self.editor)
                return
            }
            guard response == .alertFirstButtonReturn else { return }
            var raw = address.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !raw.contains(":") { raw = "https://" + raw }
            guard let url = URL(string: raw), let scheme = url.scheme?.lowercased(),
                  ["https", "http", "mailto"].contains(scheme),
                  (scheme == "mailto" ? !url.path.isEmpty : url.host?.isEmpty == false) else {
                self.showError(NSError(domain: "KodmozWriter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Geçerli bir http, https veya mailto adresi girin."]))
                return
            }
            let title = text.stringValue.isEmpty ? url.absoluteString : text.stringValue
            let replacement: NSMutableAttributedString
            if range.length > 0 && title == selected {
                replacement = NSMutableAttributedString(attributedString: self.editor.textStorage!.attributedSubstring(from: range))
            } else {
                replacement = NSMutableAttributedString(string: title, attributes: self.editor.typingAttributes)
            }
            replacement.addAttribute(.link, value: url, range: NSRange(location: 0, length: replacement.length))
            if self.editor.shouldChangeText(in: range, replacementString: title) {
                self.editor.textStorage?.replaceCharacters(in: range, with: replacement)
                self.editor.didChangeText()
                self.editor.setSelectedRange(NSRange(location: range.location + replacement.length, length: 0))
                var attrs = self.editor.typingAttributes; attrs.removeValue(forKey: .link)
                self.editor.typingAttributes = attrs
                self.window.makeFirstResponder(self.editor)
            }
        }
    }
    @objc func bold() { toggleTrait(.boldFontMask) }
    @objc func italic() { toggleTrait(.italicFontMask) }
    func toggleTrait(_ trait: NSFontTraitMask) {
        let range = editor.selectedRange()
        let manager = NSFontManager.shared
        let font = (range.length > 0 ? editor.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont : editor.typingAttributes[.font] as? NSFont) ?? .systemFont(ofSize: 24)
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
        editor.linkTextAttributes = [.foregroundColor: ink, .underlineStyle: NSUnderlineStyle.single.rawValue]
        var attrs = editor.typingAttributes; attrs[.foregroundColor] = ink
        if attrs[.font] == nil { attrs[.font] = NSFont.systemFont(ofSize: 24) }
        let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 10
        attrs[.paragraphStyle] = paragraph; editor.typingAttributes = attrs
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
        if let settings { settings.makeKeyAndOrderFront(nil); return }
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 650, height: 540), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = "Görünüm"; panel.isReleasedWhenClosed = false; panel.collectionBehavior = [.fullScreenAuxiliary]
        let stack = NSStackView(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false; panel.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor, constant: 24), stack.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor, constant: -24), stack.topAnchor.constraint(equalTo: panel.contentView!.topAnchor, constant: 24)])
        func label(_ text: String) { let label = NSTextField(labelWithString: text); label.font = .systemFont(ofSize: 13, weight: .semibold); stack.addArrangedSubview(label) }
        label("RENKLER")
        for row in 0..<2 {
            let line = NSStackView(); line.spacing = 8
            for i in row*5..<row*5+5 { let b = NSButton(title: palettes[i].name, target: self, action: #selector(choosePalette)); b.tag = i; b.bezelColor = palettes[i].color; b.widthAnchor.constraint(equalToConstant: 110).isActive = true; line.addArrangedSubview(b) }
            stack.addArrangedSubview(line)
        }
        label("MANZARALAR")
        for row in 0..<2 {
            let line = NSStackView(); line.spacing = 8
            for i in row*5..<row*5+5 {
                let b = NSButton(title: sceneNames[i], image: landscape(i), target: self, action: #selector(chooseScene)); b.tag = i; b.imagePosition = .imageAbove; b.imageScaling = .scaleProportionallyUpOrDown
                b.widthAnchor.constraint(equalToConstant: 110).isActive = true; b.heightAnchor.constraint(equalToConstant: 86).isActive = true; line.addArrangedSubview(b)
            }
            stack.addArrangedSubview(line)
        }
        let custom = NSStackView(); custom.spacing = 10
        custom.addArrangedSubview(NSButton(title: "Kendi Rengim…", target: self, action: #selector(customColor)))
        custom.addArrangedSubview(NSButton(title: "Görsel Seç…", target: self, action: #selector(customImage))); stack.addArrangedSubview(custom)
        label("⌘L Bağlantı   ·   ⌘B Kalın   ·   ⌘I İtalik   ·   ⌘U Altı çizili   ·   ⌘T Yazı tipi")
        let hint = NSTextField(wrappingLabelWithString: "Her değişiklik anında kaydedilir. Yeni yazı: ⌘N. Not menüsü: sol kenar veya ⇧⌘L. ⌘S ile RTF olarak dışa aktar. Bu pencereyi kapatıp yazmaya devam et. Görseller, okunabilirlik için karartılır.")
        hint.textColor = .secondaryLabelColor; stack.addArrangedSubview(hint)
        settings = panel; window.addChildWindow(panel, ordered: .above); panel.center(); panel.makeKeyAndOrderFront(nil)
    }
    func textDidChange(_ notification: Notification) {
        guard !loadingNote else { return }
        if saveCurrentNote() { rebuildNotes() }
    }
    @discardableResult
    func saveCurrentNote() -> Bool {
        guard !currentNoteID.isEmpty else { return true }
        guard let data = editor.rtf(from: NSRange(location: 0, length: editor.string.utf16.count)) else { return false }
        do { try data.write(to: noteURL(currentNoteID), options: .atomic); return true }
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
