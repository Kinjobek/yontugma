// YonTugma — sichqonchaning yon tugmalarini (4 va 5) Mac'da ishlatish uchun
// kichik menyu-bar ilovasi. Faqat Apple kutubxonalari ishlatilgan.

import AppKit
import ApplicationServices
import ServiceManagement
import IOKit.hid

// MARK: - Amallar (actions)

struct Preset {
    let id: String
    let title: String
}

// Menyuda ko'rinadigan tayyor amallar.
let presets: [Preset] = [
    Preset(id: "pass", title: "Özgartirmaslik (oddiy işlaşi)"),
    Preset(id: "block", title: "Heç narsa qilmaslik (öçiriş)"),
    Preset(id: "back", title: "Orqaga  (⌘[)"),
    Preset(id: "forward", title: "Oldinga  (⌘])"),
    Preset(id: "volumeUp", title: "Ovozni balandlatiş  (🔊)"),
    Preset(id: "volumeDown", title: "Ovozni pasaytiriş  (🔉)"),
    Preset(id: "mute", title: "Ovozni öçiriş / yoqiş  (🔇)"),
    Preset(id: "mission", title: "Mission Control"),
    Preset(id: "appexpose", title: "Ilova oynalari  (⌃↓)"),
    Preset(id: "desktop", title: "Iş stolini körsatiş"),
    Preset(id: "spaceLeft", title: "Çapdagi iş stoliga ötiş  (⌃←)"),
    Preset(id: "spaceRight", title: "Öngdagi iş stoliga ötiş  (⌃→)"),
    Preset(id: "prevTab", title: "Oldingi tab  (⌃⇧⇥)"),
    Preset(id: "nextTab", title: "Keyingi tab  (⌃⇥)"),
    Preset(id: "newTab", title: "Yangi tab  (⌘T)"),
    Preset(id: "closeTab", title: "Tabni yopiş  (⌘W)"),
    Preset(id: "reopenTab", title: "Yopilgan tabni qaytariş  (⌘⇧T)"),
    Preset(id: "copy", title: "Nusxa oliş  (⌘C)"),
    Preset(id: "paste", title: "Qöyiş  (⌘V)"),
    Preset(id: "undo", title: "Bekor qiliş  (⌘Z)"),
]

let defaultGlobal: [String: String] = ["4": "back", "5": "forward"]

// Sozlanadigan tugmalar: 3 = g'ildirak bosilishi, 4 va 5 = yon tugmalar.
let configurableButtons: [(num: String, title: String)] = [
    ("4", "4-tugma (yon, odatda «Orqaga»)"),
    ("5", "5-tugma (yon, odatda «Oldinga»)"),
    ("3", "Ğildirakni bosiş (3-tugma)"),
]

func titleFor(_ id: String) -> String {
    if let p = presets.first(where: { $0.id == id }) { return p.title }
    if let combo = parseCustom(id) { return "Maxsus: \(combo.title)" }
    return id
}

struct Combo {
    let keyCode: CGKeyCode
    let flags: CGEventFlags
    let title: String
}

// "custom:<kod>:<bayroqlar>:<nom>"
func parseCustom(_ id: String) -> Combo? {
    let parts = id.split(separator: ":", maxSplits: 3, omittingEmptySubsequences: false)
    guard parts.count == 4, parts[0] == "custom",
          let code = UInt16(parts[1]), let fl = UInt64(parts[2]) else { return nil }
    return Combo(keyCode: code, flags: CGEventFlags(rawValue: fl), title: String(parts[3]))
}

func postKey(_ code: CGKeyCode, _ flags: CGEventFlags) {
    let src = CGEventSource(stateID: .hidSystemState)
    for down in [true, false] {
        let e = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: down)
        e?.flags = flags
        e?.post(tap: .cghidEventTap)
    }
}

let arrowFlags: CGEventFlags = [.maskControl, .maskSecondaryFn, .maskNumericPad]

// Klaviaturadagi ovoz tugmalari (F10/F11/F12) bilan bir xil: macOS ovoz belgisini ham ko'rsatadi.
// NX_KEYTYPE_SOUND_UP = 0, NX_KEYTYPE_SOUND_DOWN = 1, NX_KEYTYPE_MUTE = 7
func postMediaKey(_ key: Int) {
    for down in [true, false] {
        let flags = NSEvent.ModifierFlags(rawValue: down ? 0xa00 : 0xb00)
        let data1 = (key << 16) | ((down ? 0xa : 0xb) << 8)
        let e = NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: flags,
                                   timestamp: 0, windowNumber: 0, context: nil,
                                   subtype: 8, data1: data1, data2: -1)
        e?.cgEvent?.post(tap: .cghidEventTap)
    }
}

func perform(_ id: String) {
    switch id {
    case "back": postKey(33, .maskCommand)              // [
    case "forward": postKey(30, .maskCommand)           // ]
    case "volumeUp": postMediaKey(0)
    case "volumeDown": postMediaKey(1)
    case "mute": postMediaKey(7)
    case "mission":
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))
    case "appexpose": postKey(125, arrowFlags)          // ⌃↓
    case "desktop": postKey(103, [.maskSecondaryFn])     // F11
    case "spaceLeft": postKey(123, arrowFlags)          // ⌃←
    case "spaceRight": postKey(124, arrowFlags)         // ⌃→
    case "prevTab": postKey(48, [.maskControl, .maskShift])
    case "nextTab": postKey(48, .maskControl)
    case "newTab": postKey(17, .maskCommand)
    case "closeTab": postKey(13, .maskCommand)
    case "reopenTab": postKey(17, [.maskCommand, .maskShift])
    case "copy": postKey(8, .maskCommand)
    case "paste": postKey(9, .maskCommand)
    case "undo": postKey(6, .maskCommand)
    default:
        if let c = parseCustom(id) { postKey(c.keyCode, c.flags) }
    }
}

// MARK: - Sozlamalar

struct Settings: Codable {
    var enabled = true
    var global: [String: String] = defaultGlobal
    var perApp: [String: [String: String]] = [:]   // bundleID -> tugma -> amal
    var appNames: [String: String] = [:]           // bundleID -> ilova nomi
}

final class Store {
    static let shared = Store()
    private let key = "settings.v1"
    var s: Settings {
        didSet { save() }
    }
    private init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let v = try? JSONDecoder().decode(Settings.self, from: d) {
            s = v
        } else {
            s = Settings()
        }
    }
    private func save() {
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: key) }
    }
    func action(button: String, bundleID: String?) -> String {
        if let b = bundleID, let a = s.perApp[b]?[button] { return a }
        return s.global[button] ?? "pass"
    }
}

// MARK: - Sichqoncha hodisalarini ushlash (CGEventTap)

final class Engine {
    static let shared = Engine()
    var tap: CFMachPort?
    var diagTap: CFMachPort?

    func startDiag() {
        if diagTap != nil { return }
        var mask: UInt64 = 0
        for t: UInt32 in [1, 2, 3, 4, 10, 11, 12, 14, 22, 25, 26, 29, 30, 31] { mask |= 1 << UInt64(t) }
        guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap,
                                        options: .listenOnly, eventsOfInterest: mask,
                                        callback: { _, type, ev, _ in
            if type.rawValue < 0x7fff_fff0 {
                var extra = ""
                if type == .keyDown || type == .keyUp { extra = " key=\(ev.getIntegerValueField(.keyboardEventKeycode)) flags=\(String(ev.flags.rawValue, radix: 16))" }
                if type == .otherMouseDown || type == .otherMouseUp { extra = " button=\(ev.getIntegerValueField(.mouseEventButtonNumber) + 1)" }
                if type == .scrollWheel { extra = " dy=\(ev.getIntegerValueField(.scrollWheelEventDeltaAxis1)) dx=\(ev.getIntegerValueField(.scrollWheelEventDeltaAxis2))" }
                if type.rawValue == 14, let ns = NSEvent(cgEvent: ev) { extra = " subtype=\(ns.subtype.rawValue) data1=\(String(ns.data1, radix: 16))" }
                DiagLog.shared.write("EVENT type=\(type.rawValue)" + extra)
            }
            return Unmanaged.passUnretained(ev)
        }, userInfo: nil) else { DiagLog.shared.write("diag tap: yaratib bölmadi"); return }
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, t, 0), .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
        diagTap = t
    }
    var onButton: ((Int) -> Void)?   // sinash oynasi uchun

    var isRunning: Bool { tap != nil }

    func start() -> Bool {
        if tap != nil { return true }
        let mask = (1 << CGEventType.otherMouseDown.rawValue) | (1 << CGEventType.otherMouseUp.rawValue)
        guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                        place: .headInsertEventTap,
                                        options: .defaultTap,
                                        eventsOfInterest: CGEventMask(mask),
                                        callback: tapCallback,
                                        userInfo: nil) else { return false }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, t, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
        tap = t
        return true
    }
}

func tapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                 refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let t = Engine.shared.tap { CGEvent.tapEnable(tap: t, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    // macOS 0 dan sanaydi: 2 = g'ildirak, 3 = 4-tugma, 4 = 5-tugma.
    let button = Int(event.getIntegerValueField(.mouseEventButtonNumber)) + 1
    // Yashirin yon tugma bosilganda macOS uni g'ildirak bosishi deb yuborishi mumkin — yutamiz.
    if button == 3 && HIDReader.shared.hiddenRecentlyActive() { return nil }
    if type == .otherMouseDown { Engine.shared.onButton?(button) }
    return handleButton(button, down: type == .otherMouseDown) ? nil : Unmanaged.passUnretained(event)
}

/// Tugma uchun amal bajaradi. true = asl hodisani yutish kerak.
func handleButton(_ button: Int, down: Bool) -> Bool {
    let store = Store.shared
    guard store.s.enabled else { return false }
    let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    let action = store.action(button: String(button), bundleID: bundleID)
    if action == "pass" { return false }
    if down && action != "block" {
        DispatchQueue.main.async { perform(action) }
    }
    return true
}

// MARK: - Sichqonchadan to'g'ridan-to'g'ri o'qish (IOHID)
// Ba'zi arzon siçqonçalar (masalan Xiaomi) o'zini 3 tugmali deb e'lon qiladi,
// lekin 4/5-tugmalarni "yaşirin" bitlarda yuboradi. macOS ularni ko'rmaydi,
// shuning uchun xom hisobotni (raw report) o'zimiz o'qiymiz.

struct ButtonField {
    let reportID: UInt8
    let bitOffset: Int
    let button: Int
    let hidden: Bool   // e'lon qilingan tugmalar doirasidan tashqarida
}

func parseButtonFields(_ d: [UInt8]) -> (fields: [ButtonField], usesIDs: Bool) {
    var fields: [ButtonField] = []
    var usagePage: UInt32 = 0, reportSize = 0, reportCount = 0
    var reportID: UInt8 = 0, usesIDs = false
    var usages: [UInt32] = [], uMin: UInt32? = nil, uMax: UInt32? = nil
    var offsets: [UInt8: Int] = [:]
    var i = 0
    while i < d.count {
        let p = d[i]
        if p == 0xFE {   // uzun element
            guard i + 1 < d.count else { break }
            i += 3 + Int(d[i + 1]); continue
        }
        let size = [0, 1, 2, 4][Int(p & 3)]
        let type = (p >> 2) & 3, tag = p >> 4
        var v: UInt32 = 0
        for k in 0..<size where i + 1 + k < d.count { v |= UInt32(d[i + 1 + k]) << (8 * k) }
        i += 1 + size
        switch (type, tag) {
        case (1, 0x0): usagePage = v
        case (1, 0x7): reportSize = Int(v)
        case (1, 0x8): reportID = UInt8(truncatingIfNeeded: v); usesIDs = true
        case (1, 0x9): reportCount = Int(v)
        case (2, 0x0): usages.append(v)
        case (2, 0x1): uMin = v
        case (2, 0x2): uMax = v
        case (0, 0x8):   // Input
            let off = offsets[reportID] ?? 0
            let isConst = v & 1 == 1
            if usagePage == 9 && !isConst && reportSize == 1 {
                for n in 0..<reportCount {
                    var btn: Int
                    var hidden = false
                    if let a = uMin {
                        btn = Int(a) + n
                        if let b = uMax, btn > Int(b) { hidden = true }
                    } else if n < usages.count {
                        btn = Int(usages[n])
                    } else {
                        btn = Int(usages.last ?? 0) + (n - usages.count + 1); hidden = true
                    }
                    fields.append(ButtonField(reportID: reportID, bitOffset: off + n, button: btn, hidden: hidden))
                }
            }
            offsets[reportID] = off + reportSize * reportCount
            usages = []; uMin = nil; uMax = nil
        case (0, _):
            usages = []; uMin = nil; uMax = nil
        default: break
        }
    }
    return (fields, usesIDs)
}

// Tashxis (diagnostika) uchun yozuv: sinash oynasi ochiq bo'lganda ~/Library/Logs/YonTugma.log ga yoziladi.
final class DiagLog {
    static let shared = DiagLog()
    var enabled = false
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/YonTugma.log")
    let fmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"; return f }()
    func write(_ line: String) {
        guard enabled else { return }
        if let a = try? FileManager.default.attributesOfItem(atPath: url.path),
           let n = a[.size] as? Int, n > 5_000_000 { try? FileManager.default.removeItem(at: url) }
        let text = fmt.string(from: Date()) + " " + line + "\n"
        if let h = try? FileHandle(forWritingTo: url) {
            h.seekToEndOfFile(); h.write(text.data(using: .utf8)!); try? h.close()
        } else {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

final class HIDDevState {
    var name = "?"
    var regID: UInt64 = 0
    let fields: [ButtonField]
    let usesIDs: Bool
    var down: Set<Int> = []
    let buffer: UnsafeMutablePointer<UInt8>
    init(fields: [ButtonField], usesIDs: Bool, size: Int) {
        self.fields = fields; self.usesIDs = usesIDs
        buffer = .allocate(capacity: max(size, 64))
    }
}

final class HIDReader {
    static let shared = HIDReader()
    var manager: IOHIDManager?
    var states: [HIDDevState] = []
    var onRaw: ((String) -> Void)?
    var hiddenDownCount = 0
    var lastHiddenChange = Date.distantPast
    var isOpen = false

    func hiddenRecentlyActive() -> Bool {
        hiddenDownCount > 0 || Date().timeIntervalSince(lastHiddenChange) < 0.15
    }

    static var hasAccess: Bool { IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted }

    func start() {
        if isOpen { return }
        guard HIDReader.hasAccess else { return }
        let m = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(m, [kIOHIDDeviceUsagePageKey: 1, kIOHIDDeviceUsageKey: 2] as CFDictionary)
        IOHIDManagerRegisterDeviceMatchingCallback(m, { _, _, _, dev in
            HIDReader.shared.attach(dev)
        }, nil)
        IOHIDManagerScheduleWithRunLoop(m, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        guard IOHIDManagerOpen(m, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else { return }
        manager = m
        isOpen = true
    }

    func attach(_ dev: IOHIDDevice) {
        guard let desc = IOHIDDeviceGetProperty(dev, kIOHIDReportDescriptorKey as CFString) as? Data else { return }
        let parsed = parseButtonFields([UInt8](desc))
        // Faqat yashirin tugmalari bor sichqonchalarni kuzatamiz; qolganlarini macOS o'zi to'g'ri ko'radi.
        let hidden = parsed.fields.filter { $0.hidden }
        let name = (IOHIDDeviceGetProperty(dev, kIOHIDProductKey as CFString) as? String) ?? "?"
        // Bitta sichqoncha bir necha marta topilishi mumkin — faqat bir marta ulaymiz.
        var regID: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(IOHIDDeviceGetService(dev), &regID)
        if states.contains(where: { $0.regID == regID }) { return }
        guard !hidden.isEmpty || DiagLog.shared.enabled else { return }
        let size = (IOHIDDeviceGetProperty(dev, kIOHIDMaxInputReportSizeKey as CFString) as? Int) ?? 64
        let st = HIDDevState(fields: hidden, usesIDs: parsed.usesIDs, size: size)
        st.name = name
        st.regID = regID
        states.append(st)
        let ctx = Unmanaged.passUnretained(st).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(dev, st.buffer, max(size, 64), { ctx, _, _, _, rid, report, len in
            guard let ctx = ctx else { return }
            let st = Unmanaged<HIDDevState>.fromOpaque(ctx).takeUnretainedValue()
            HIDReader.shared.handle(st, reportID: UInt8(truncatingIfNeeded: rid), report: report, len: len)
        }, ctx)
    }

    func handle(_ st: HIDDevState, reportID: UInt8, report: UnsafeMutablePointer<UInt8>, len: CFIndex) {
        DiagLog.shared.write("HID [\(st.name)] id=\(reportID) len=\(len): " + (0..<len).map { String(format: "%02x", report[$0]) }.joined(separator: " "))
        if let f = onRaw {
            f((0..<len).map { String(format: "%02x", report[$0]) }.joined(separator: " "))
        }
        let base = st.usesIDs ? 8 : 0
        for fld in st.fields where !st.usesIDs || fld.reportID == reportID {
            let bit = base + fld.bitOffset
            guard bit / 8 < len else { continue }
            let pressed = report[bit / 8] & (1 << UInt8(bit % 8)) != 0
            let was = st.down.contains(fld.button)
            if pressed == was { continue }
            if pressed { st.down.insert(fld.button); hiddenDownCount += 1 }
            else { st.down.remove(fld.button); hiddenDownCount = max(0, hiddenDownCount - 1) }
            lastHiddenChange = Date()
            if pressed { Engine.shared.onButton?(fld.button) }
            _ = handleButton(fld.button, down: pressed)
        }
    }
}

// MARK: - Ruxsat (Accessibility)

func isTrusted(prompt: Bool) -> Bool {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(opts)
}

func openAccessibilitySettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Ilova

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    func windowWillClose(_ n: Notification) {
        if (n.object as? NSWindow) === testWindow {
            DiagLog.shared.enabled = false
            Engine.shared.onButton = nil
            HIDReader.shared.onRaw = nil
            if let t = Engine.shared.diagTap { CGEvent.tapEnable(tap: t, enable: false) }
        }
    }

    var statusItem: NSStatusItem!
    var menu = NSMenu()
    var lastApp: NSRunningApplication?
    var permissionTimer: Timer?
    var testWindow: NSWindow?
    var testLabel: NSTextField?
    var rawLabel: NSTextField?
    var localMonitor: Any?
    var recorderWindow: NSWindow?
    var recorderMonitor: Any?

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu.delegate = self
        statusItem.menu = menu
        updateIcon()

        lastApp = NSWorkspace.shared.frontmostApplication
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] note in
            if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               app.bundleIdentifier != Bundle.main.bundleIdentifier {
                self?.lastApp = app
            }
        }

        if isTrusted(prompt: false) {
            _ = Engine.shared.start()
        } else {
            showPermissionHelp()
        }
        if HIDReader.hasAccess {
            HIDReader.shared.start()
        } else {
            _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)   // ro'yxatga qo'shadi va so'raydi
        }
        waitForPermission()
        updateIcon()
    }

    @objc func askInputMonitoring() {
        _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
        waitForPermission()
    }

    func waitForPermission() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] t in
            if isTrusted(prompt: false) { _ = Engine.shared.start() }
            if HIDReader.hasAccess { HIDReader.shared.start() }
            self?.updateIcon()
            if Engine.shared.isRunning && HIDReader.shared.isOpen { t.invalidate() }
        }
    }

    func showPermissionHelp() {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = "YonTugma'ga ruxsat kerak"
        a.informativeText = """
        Sichqoncha tugmalarini ushlash uchun macOS «Accessibility» (Universal kirish) ruxsatini so'raydi.

        1. «Sozlamalarni ochish» tugmasini bosing.
        2. Ro'yxatda «YonTugma» yonidagi kalitni yoqing (parol yoki Touch ID so'ralishi mumkin).
        3. Shu bilan tamom — ilova o'zi ishlay boshlaydi.
        """
        a.addButton(withTitle: "Sozlamalarni oçiş")
        a.addButton(withTitle: "Keyinroq")
        if a.runModal() == .alertFirstButtonReturn {
            _ = isTrusted(prompt: true)   // YonTugma'ni ro'yxatga qo'shadi
            openAccessibilitySettings()
        }
    }

    func updateIcon() {
        guard let b = statusItem.button else { return }
        let on = Store.shared.s.enabled && Engine.shared.isRunning
        let name = on ? "computermouse.fill" : "computermouse"
        b.image = NSImage(systemSymbolName: name, accessibilityDescription: "YonTugma")
        b.appearsDisabled = !on
        b.toolTip = on ? "YonTugma: yoqilgan" : "YonTugma: öçirilgan"
    }

    // Menyu har safar ochilganda qaytadan quriladi.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let st = Store.shared.s

        if !Engine.shared.isRunning {
            let w = NSMenuItem(title: "⚠️ Ruxsat kerak — şu yerni bosing", action: #selector(askPermission), keyEquivalent: "")
            w.target = self
            menu.addItem(w)
        }
        if !HIDReader.shared.isOpen {
            let w = NSMenuItem(title: "⚠️ «Kiritişni kuzatiş» ruxsati kerak — bosing", action: #selector(askInputMonitoring), keyEquivalent: "")
            w.target = self
            menu.addItem(w)
        }
        if !Engine.shared.isRunning || !HIDReader.shared.isOpen { menu.addItem(.separator()) }

        let toggle = NSMenuItem(title: "Yoqilgan", action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        toggle.state = st.enabled ? .on : .off
        menu.addItem(toggle)
        menu.addItem(.separator())

        menu.addItem(header("Barça ilovalar uçun"))
        for b in configurableButtons {
            let cur = st.global[b.num] ?? "pass"
            let item = NSMenuItem(title: "\(b.title):  \(short(cur))", action: nil, keyEquivalent: "")
            item.submenu = actionsMenu(button: b.num, bundleID: nil, current: cur)
            menu.addItem(item)
        }
        let quick = NSMenuItem(title: "Tayyor toplamlar", action: nil, keyEquivalent: "")
        let qm = NSMenu()
        for (title, b4, b5) in [("4 / 5 = Orqaga / Oldinga", "back", "forward"),
                                ("4 / 5 = Ovoz pasaytiriş / balandlatiş", "volumeDown", "volumeUp")] {
            let it = NSMenuItem(title: title, action: #selector(applyQuick(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = [b4, b5]
            it.state = (st.global["4"] == b4 && st.global["5"] == b5) ? .on : .off
            qm.addItem(it)
        }
        quick.submenu = qm
        menu.addItem(quick)

        menu.addItem(.separator())
        if let app = lastApp, let bid = app.bundleIdentifier {
            let name = app.localizedName ?? bid
            menu.addItem(header("Faqat «\(name)» uçun"))
            for b in configurableButtons {
                let cur = st.perApp[bid]?[b.num]
                let shown = cur.map { short($0) } ?? "umumiy sozlama"
                let item = NSMenuItem(title: "\(b.title):  \(shown)", action: nil, keyEquivalent: "")
                item.submenu = actionsMenu(button: b.num, bundleID: bid, current: cur, appName: name)
                menu.addItem(item)
            }
        }

        if !st.perApp.isEmpty {
            let list = NSMenuItem(title: "Alohida sozlangan ilovalar", action: nil, keyEquivalent: "")
            let sub = NSMenu()
            let hint = NSMenuItem(title: "Bosilsa, şu ilova sozlamasi öçiriladi:", action: nil, keyEquivalent: "")
            hint.isEnabled = false
            sub.addItem(hint)
            for bid in st.perApp.keys.sorted() {
                let it = NSMenuItem(title: "✕  " + (st.appNames[bid] ?? bid), action: #selector(removeApp(_:)), keyEquivalent: "")
                it.target = self
                it.representedObject = bid
                sub.addItem(it)
            }
            list.submenu = sub
            menu.addItem(list)
        }

        menu.addItem(.separator())
        let test = NSMenuItem(title: "Tugmalarni sinaş…", action: #selector(openTest), keyEquivalent: "")
        test.target = self
        menu.addItem(test)

        let login = NSMenuItem(title: "Kompyuter yonganda işga tuşiriş", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        let reset = NSMenuItem(title: "Standart sozlamalarga qaytariş", action: #selector(resetAll), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "YonTugma'dan çiqiş", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    func header(_ t: String) -> NSMenuItem {
        let i = NSMenuItem(title: t, action: nil, keyEquivalent: "")
        i.isEnabled = false
        return i
    }

    func short(_ id: String) -> String {
        let t = titleFor(id)
        if let r = t.range(of: "  (") { return String(t[..<r.lowerBound]) }
        return t
    }

    struct Choice {
        let button: String
        let bundleID: String?
        let appName: String?
        let action: String?   // nil = umumiy sozlamaga qaytish
    }

    func actionsMenu(button: String, bundleID: String?, current: String?, appName: String? = nil) -> NSMenu {
        let m = NSMenu()
        if bundleID != nil {
            let i = NSMenuItem(title: "Umumiy sozlamadan foydalaniş", action: #selector(choose(_:)), keyEquivalent: "")
            i.target = self
            i.representedObject = Choice(button: button, bundleID: bundleID, appName: appName, action: nil)
            i.state = current == nil ? .on : .off
            m.addItem(i)
            m.addItem(.separator())
        }
        for p in presets {
            let i = NSMenuItem(title: p.title, action: #selector(choose(_:)), keyEquivalent: "")
            i.target = self
            i.representedObject = Choice(button: button, bundleID: bundleID, appName: appName, action: p.id)
            i.state = current == p.id ? .on : .off
            m.addItem(i)
            if p.id == "block" { m.addItem(.separator()) }
        }
        m.addItem(.separator())
        if let cur = current, cur.hasPrefix("custom:") {
            let i = NSMenuItem(title: titleFor(cur), action: nil, keyEquivalent: "")
            i.state = .on
            m.addItem(i)
        }
        let rec = NSMenuItem(title: "Boşqa tugmalar birikmasi…", action: #selector(recordCustom(_:)), keyEquivalent: "")
        rec.target = self
        rec.representedObject = Choice(button: button, bundleID: bundleID, appName: appName, action: nil)
        m.addItem(rec)
        return m
    }

    func apply(_ c: Choice) {
        var st = Store.shared.s
        if let bid = c.bundleID {
            var map = st.perApp[bid] ?? [:]
            map[c.button] = c.action
            if map.isEmpty {
                st.perApp[bid] = nil
                st.appNames[bid] = nil
            } else {
                st.perApp[bid] = map
                st.appNames[bid] = c.appName ?? bid
            }
        } else {
            st.global[c.button] = c.action ?? "pass"
        }
        Store.shared.s = st
    }

    @objc func choose(_ sender: NSMenuItem) {
        if let c = sender.representedObject as? Choice { apply(c) }
    }

    @objc func removeApp(_ sender: NSMenuItem) {
        guard let bid = sender.representedObject as? String else { return }
        Store.shared.s.perApp[bid] = nil
        Store.shared.s.appNames[bid] = nil
    }

    @objc func toggleEnabled() {
        Store.shared.s.enabled.toggle()
        updateIcon()
    }

    @objc func askPermission() {
        showPermissionHelp()
        waitForPermission()
    }

    @objc func applyQuick(_ sender: NSMenuItem) {
        guard let pair = sender.representedObject as? [String], pair.count == 2 else { return }
        Store.shared.s.global["4"] = pair[0]
        Store.shared.s.global["5"] = pair[1]
    }

    @objc func resetAll() {
        let keepEnabled = Store.shared.s.enabled
        var s = Settings()
        s.enabled = keepEnabled
        Store.shared.s = s
    }

    @objc func toggleLogin() {
        let svc = SMAppService.mainApp
        do {
            if svc.status == .enabled {
                try svc.unregister()
            } else {
                try svc.register()
                if svc.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
        } catch {
            let a = NSAlert()
            a.messageText = "Avtomatik işga tuşirişni yoqib bölmadi"
            a.informativeText = "Qölda qöşing: Tizim sozlamalari → Umumiy → Login elementlari → «+» → YonTugma.\n\n(\(error.localizedDescription))"
            NSApp.activate(ignoringOtherApps: true)
            a.runModal()
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    // MARK: Sinash oynasi

    @objc func openTest() {
        if testWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 250),
                             styleMask: [.titled, .closable], backing: .buffered, defer: false)
            w.title = "YonTugma — tugmalarni sinaş"
            w.delegate = self
            w.isReleasedWhenClosed = false
            let intro = NSTextField(wrappingLabelWithString:
                "Yon tugmalarni bosing (körsatkiç şu oyna ustida bölsin).\n" +
                "4 yoki 5 çiqsa — tugmalar bor va işlaydi.\n" +
                "Heç narsa çiqmasa — ikkala ruxsat (Universal kiriş va Kiritişni kuzatiş) berilganini tekşiring va ilovani qayta oçing.")
            intro.frame = NSRect(x: 20, y: 125, width: 400, height: 110)
            let big = NSTextField(labelWithString: "Tugmani bosing…")
            big.font = .systemFont(ofSize: 22, weight: .semibold)
            big.alignment = .center
            big.frame = NSRect(x: 20, y: 75, width: 400, height: 40)
            let raw = NSTextField(labelWithString: "Xom ma'lumot: —")
            raw.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            raw.textColor = .secondaryLabelColor
            raw.frame = NSRect(x: 20, y: 25, width: 400, height: 30)
            w.contentView?.addSubview(intro)
            w.contentView?.addSubview(big)
            w.contentView?.addSubview(raw)
            rawLabel = raw
            w.center()
            testWindow = w
            testLabel = big
        }
        let show: (Int) -> Void = { [weak self] n in
            self?.testLabel?.stringValue = "Siz \(n)-tugmani bosdingiz  (\(Date().formatted(date: .omitted, time: .standard)))"
        }
        Engine.shared.onButton = show
        DiagLog.shared.enabled = true
        DiagLog.shared.write("=== sinaş oynasi oçildi; accessibility=\(isTrusted(prompt: false)) hidAccess=\(HIDReader.hasAccess) hidOpen=\(HIDReader.shared.isOpen) qurilmalar=\(HIDReader.shared.states.map { "\($0.name)(yashirin:\($0.fields.count))" })")
        Engine.shared.startDiag()
        if let t = Engine.shared.diagTap { CGEvent.tapEnable(tap: t, enable: true) }
        HIDReader.shared.onRaw = { [weak self] s in self?.rawLabel?.stringValue = "Xom ma'lumot: " + s }
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.otherMouseDown]) { e in
                if !Engine.shared.isRunning { show(e.buttonNumber + 1) }
                return e
            }
        }
        NSApp.activate(ignoringOtherApps: true)
        testWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: Maxsus tugmalar birikmasini yozib olish

    @objc func recordCustom(_ sender: NSMenuItem) {
        guard let base = sender.representedObject as? Choice else { return }
        recorderWindow?.close()
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 140),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Tugmalar birikmasini bosing"
        w.isReleasedWhenClosed = false
        let l = NSTextField(wrappingLabelWithString:
            "Klaviaturada kerakli birikmani bosing (masalan ⌘⇧T).\nBekor qiliş uçun Esc.")
        l.frame = NSRect(x: 20, y: 40, width: 380, height: 70)
        w.contentView?.addSubview(l)
        w.center()
        recorderWindow = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)

        recorderMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] e in
            guard let self = self else { return e }
            if e.keyCode == 53 && e.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                self.finishRecording()
                return nil
            }
            let mods = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
            var flags: CGEventFlags = []
            var t = ""
            if mods.contains(.control) { flags.insert(.maskControl); t += "⌃" }
            if mods.contains(.option) { flags.insert(.maskAlternate); t += "⌥" }
            if mods.contains(.shift) { flags.insert(.maskShift); t += "⇧" }
            if mods.contains(.command) { flags.insert(.maskCommand); t += "⌘" }
            if mods.contains(.function) { flags.insert(.maskSecondaryFn) }
            t += keyName(e)
            let id = "custom:\(e.keyCode):\(flags.rawValue):\(t)"
            self.apply(Choice(button: base.button, bundleID: base.bundleID, appName: base.appName, action: id))
            self.finishRecording()
            return nil
        }
    }

    func finishRecording() {
        if let m = recorderMonitor { NSEvent.removeMonitor(m) }
        recorderMonitor = nil
        recorderWindow?.close()
    }
}

func keyName(_ e: NSEvent) -> String {
    let special: [UInt16: String] = [
        123: "←", 124: "→", 125: "↓", 126: "↑", 48: "⇥", 49: "Space", 36: "↩",
        51: "⌫", 117: "⌦", 115: "Home", 119: "End", 116: "PgUp", 121: "PgDn",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7",
        100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]
    if let s = special[e.keyCode] { return s }
    return (e.charactersIgnoringModifiers ?? "?").uppercased()
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
