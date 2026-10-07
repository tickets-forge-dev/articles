#!/usr/bin/env swift
// macOS only; no packages. Run from the article root:
// swift scripts/circular-heroes.swift render|check SNAPSHOT OUTPUT_DIR
// render stages heroes/previews; check verifies installed heroes and preserved content.
import AppKit
import CryptoKit

struct Failure: Error { let message: String }
func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw Failure(message: message) }
}
let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let portraitRect = NSRect(x: 1136, y: 274, width: 352, height: 352)
let cyan = NSColor(srgbRed: 0.32, green: 0.77, blue: 1, alpha: 1)
let orange = NSColor(srgbRed: 1, green: 0.51, blue: 0.31, alpha: 1)
let white = NSColor(srgbRed: 0.96, green: 0.98, blue: 1, alpha: 1)
let muted = NSColor(srgbRed: 0.73, green: 0.83, blue: 0.92, alpha: 1)
let motifs = [
    "01-prompt-to-answer": "TOKENIZE → PREFILL → DECODE",
    "02-tokens-context-attention": "TOKENS • CONTEXT • ATTENTION",
    "08-retrieval-pipeline": "TEXT → JEV CHOICE → HUMAN REVIEW",
    "09-prefix-caching": "STABLE PREFIX → VARIABLE SUFFIX",
]
func text(_ string: String, size: CGFloat, color: NSColor, bold: Bool = false) throws -> NSAttributedString {
    try require(!string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Empty hero text")
    let style = NSMutableParagraphStyle(); style.lineBreakMode = .byWordWrapping
    return NSAttributedString(string: string, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: bold ? .bold : .medium),
        .foregroundColor: color, .paragraphStyle: style
    ])
}
func height(_ text: NSAttributedString, width: CGFloat) throws -> CGFloat {
    try require(width > 0, "Invalid text width")
    let attributes = text.attributes(at: 0, effectiveRange: nil)
    for word in text.string.split(whereSeparator: { $0.isWhitespace }) {
        try require(NSAttributedString(string: String(word), attributes: attributes).size().width <= width,
                    "Unwrappable hero word: \(word)")
    }
    return ceil(text.boundingRect(with: NSSize(width: width, height: 2000),
                                 options: [.usesLineFragmentOrigin, .usesFontLeading]).height)
}
func draw(_ text: NSAttributedString, in rect: NSRect) throws {
    try require(rect.minX >= 0 && rect.minY >= 0 && rect.maxX <= 1600 && rect.maxY <= 900,
                "Text box outside hero")
    try require(try height(text, width: rect.width) <= rect.height, "Hero text would clip: \(text.string)")
    text.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}
func png(width: Int = 1600, height: Int = 900, _ drawing: () throws -> Void) throws -> Data {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
        let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw Failure(message: "Cannot allocate hero bitmap")
    }
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    context.cgContext.translateBy(x: 0, y: CGFloat(height)); context.cgContext.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
    try drawing()
    guard let result = bitmap.representation(using: .png, properties: [:]) else {
        throw Failure(message: "Cannot encode PNG")
    }
    return result
}
func metadata(_ draft: String, slug: String) throws -> (String, String) {
    let lines = draft.components(separatedBy: "\n")
    try require(lines.count >= 3, "Missing hero metadata: \(slug)")
    try require(lines[0].hasPrefix("# ") && lines[2].hasPrefix("*") && lines[2].hasSuffix("*"), "Malformed title/subtitle")
    let title = String(lines[0].dropFirst(2))
    let subtitle = String(lines[2].dropFirst().dropLast())
    try require(!title.isEmpty && !subtitle.isEmpty, "Empty title or promise")
    return (title, subtitle)
}
func publicationLabel(_ slug: String) throws -> String {
    let order = try JSONDecoder().decode([String].self, from: Data(contentsOf: root.appendingPathComponent("content/publication-order.json")))
    try require(!order.isEmpty && Set(order).count == order.count && order.allSatisfy { motifs[$0] != nil }, "Invalid publication order")
    // Unassigned legacy drafts retain their storage number; this does not assign publication positions.
    guard let index = order.firstIndex(of: slug) else { return String(slug.prefix(2)) }
    return String(format: "%02d", index + 1)
}
func hero(_ title: String, _ promise: String, slug: String, portrait: NSImage) throws -> Data {
    guard let motif = motifs[slug] else { throw Failure(message: "Missing topic cue: \(slug)") }
    let titleText = try text(title.replacingOccurrences(of: "-", with: "‑"), size: 96, color: white, bold: true)
    let promiseText = try text(promise, size: 60, color: muted)
    let titleHeight = try height(titleText, width: 960)
    let promiseHeight = try height(promiseText, width: 960)
    let top = 450 - (titleHeight + 40 + promiseHeight) / 2
    try require(top >= 145 && 900 - top <= 785, "Title/promise collide with header/footer: \(slug)")
    return try png {
        let dark = NSColor(srgbRed: 0.015, green: 0.04, blue: 0.085, alpha: 1)
        dark.setFill(); NSRect(x: 0, y: 0, width: 1600, height: 900).fill()
        guard let glow = NSGradient(starting: NSColor(srgbRed: 0.065, green: 0.18, blue: 0.29, alpha: 1), ending: dark) else {
            throw Failure(message: "Cannot create background")
        }
        glow.draw(in: NSRect(x: 0, y: 0, width: 1600, height: 900), relativeCenterPosition: NSPoint(x: 0.64, y: 0))
        NSColor(srgbRed: 0.16, green: 0.31, blue: 0.43, alpha: 0.27).setStroke()
        let grid = NSBezierPath(); grid.lineWidth = 1
        for x in stride(from: 0, through: 1600, by: 80) {
            grid.move(to: NSPoint(x: x, y: 0)); grid.line(to: NSPoint(x: x, y: 900))
        }
        for y in stride(from: 0, through: 900, by: 75) {
            grid.move(to: NSPoint(x: 0, y: y)); grid.line(to: NSPoint(x: 1600, y: y))
        }
        grid.stroke()
        try draw(text("AI ENGINEERING FUNDAMENTALS · \(try publicationLabel(slug))", size: 40, color: cyan, bold: true),
                 in: NSRect(x: 112, y: 70, width: 1376, height: 55))
        try draw(titleText, in: NSRect(x: 112, y: top, width: 960, height: titleHeight + 2))
        try draw(promiseText, in: NSRect(x: 112, y: top + titleHeight + 40, width: 960, height: promiseHeight + 2))
        orange.setFill(); NSRect(x: 112, y: 817, width: 100, height: 5).fill()
        try draw(text(motif, size: 44, color: cyan, bold: true), in: NSRect(x: 235, y: 795, width: 1253, height: 65))
        cyan.withAlphaComponent(0.15).setFill()
        NSBezierPath(ovalIn: portraitRect.insetBy(dx: -15, dy: -15)).fill()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(ovalIn: portraitRect).addClip()
        portrait.draw(in: portraitRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
        NSGraphicsContext.restoreGraphicsState()
        cyan.setStroke(); let border = NSBezierPath(ovalIn: portraitRect); border.lineWidth = 5; border.stroke()
    }
}
func preview(_ data: Data, width: Int) throws -> Data {
    guard let source = NSImage(data: data) else { throw Failure(message: "Cannot decode preview source") }
    let h = Int((Double(width) * 9 / 16).rounded())
    return try png(width: width, height: h) {
        source.draw(in: NSRect(x: 0, y: 0, width: width, height: h), from: .zero, operation: .sourceOver,
                    fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    }
}
func bytes(_ url: URL) throws -> Data { try Data(contentsOf: url) }

do {
    let args = CommandLine.arguments
    try require(args.count == 4 && ["render", "check"].contains(args[1]), "Usage: swift scripts/circular-heroes.swift render|check SNAPSHOT OUTPUT_DIR")
    let mode = args[1], snapshot = URL(fileURLWithPath: args[2]).standardizedFileURL.resolvingSymlinksInPath()
    let output = URL(fileURLWithPath: args[3]).standardizedFileURL.resolvingSymlinksInPath()
    try require(snapshot != root && output != root && output != snapshot && !output.path.hasPrefix(snapshot.path + "/") &&
                !output.path.hasPrefix(root.appendingPathComponent("content").path + "/"), "Use separate snapshot/staging directories")
    try require(portraitRect.width / 1600 == 0.22 && portraitRect.width == portraitRect.height && portraitRect.midY == 450,
                "Portrait must be a centered 22%-width circle")
    let drafts = try fm.contentsOfDirectory(at: root.appendingPathComponent("content/drafts"), includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "md" }.sorted { $0.path < $1.path }
    try require(Set(drafts.map { $0.deletingPathExtension().lastPathComponent }) == Set(motifs.keys), "Expected exactly the four released drafts")
    let reference = root.appendingPathComponent("content/portrait.png")
    guard let portrait = NSImage(contentsOf: reference), let cg = portrait.cgImage(forProposedRect: nil, context: nil, hints: nil),
          cg.width == 680 && cg.height == 680 else {
        throw Failure(message: "Missing or incompatible approved portrait")
    }
    var rejected = false
    do { _ = try metadata("", slug: "missing") } catch { rejected = true }
    try require(rejected, "Empty metadata accepted")
    rejected = false
    do { _ = try height(text(String(repeating: "W", count: 200), size: 96, color: white), width: 960) } catch { rejected = true }
    try require(rejected, "Unwrappable title accepted")
    var manifest: [[String: Any]] = []
    // Preflight all content/rendering before writing or accepting any hero.
    var rendered: [String: Data] = [:]
    for draftURL in drafts {
        let slug = draftURL.deletingPathExtension().lastPathComponent
        let draftData = try bytes(draftURL)
        try require(draftData == bytes(snapshot.appendingPathComponent("content/drafts/\(slug).md")), "Draft changed: \(slug)")
        let draft = String(decoding: draftData, as: UTF8.self)
        let (title, promise) = try metadata(draft, slug: slug)
        let pattern = #"!\[[^\]\n]*\]\(([^)\n]+)\)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let links = regex.matches(in: draft, range: NSRange(draft.startIndex..., in: draft)).compactMap {
            Range($0.range(at: 1), in: draft).map { String(draft[$0]) }
        }
        let names = ["hero"] + (draft.contains("**When to use this:**") ? [] : ["when-to-use"]) + ["step-1", "step-2", "step-3", "step-4"]
        try require(links == names.map { "../images/\(slug)/\($0).png" }, "Image order changed")
        for name in names {
            let relative = "content/images/\(slug)/\(name).png"
            let current = try bytes(root.appendingPathComponent(relative))
            guard let rep = NSBitmapImageRep(data: current), rep.pixelsWide > 0, rep.pixelsHigh > 0 else {
                throw Failure(message: "Invalid PNG: \(relative)")
            }
            if name != "when-to-use" { try require(rep.pixelsWide == 1600 && rep.pixelsHigh == 900, "Unexpected image dimensions") }
            if name != "hero" { try require(current == bytes(snapshot.appendingPathComponent(relative)), "Non-hero image changed: \(relative)") }
        }
        let data = try hero(title, promise, slug: slug, portrait: portrait)
        rendered[slug] = data
        manifest.append(["slug": slug, "title": title, "promise": promise, "portrait": ["x": 1136, "y": 274, "diameter": 352, "widthFraction": 0.22],
                         "sha256": SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()])
    }
    try require(bytes(root.appendingPathComponent("content/when-to-use.json")) == bytes(snapshot.appendingPathComponent("content/when-to-use.json")), "Canonical cards changed")
    if mode == "render" {
        try fm.createDirectory(at: output.appendingPathComponent("mobile"), withIntermediateDirectories: true)
        try fm.createDirectory(at: output.appendingPathComponent("thumbnail"), withIntermediateDirectories: true)
        for (slug, data) in rendered {
            let directory = output.appendingPathComponent(slug)
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent("hero.png"), options: .atomic)
            try preview(data, width: 375).write(to: output.appendingPathComponent("mobile/\(slug).png"), options: .atomic)
            try preview(data, width: 240).write(to: output.appendingPathComponent("thumbnail/\(slug).png"), options: .atomic)
        }
        try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("manifest.json"), options: .atomic)
        let sheetHeight = ((rendered.count + 2) / 3) * 227 + 16
        let sheet = try png(width: 1189, height: sheetHeight) {
            NSColor(srgbRed: 0.015, green: 0.04, blue: 0.085, alpha: 1).setFill()
            NSRect(x: 0, y: 0, width: 1189, height: CGFloat(sheetHeight)).fill()
            for (index, slug) in rendered.keys.sorted().enumerated() {
                guard let data = rendered[slug], let image = NSImage(data: data) else {
                    throw Failure(message: "Missing contact-sheet image")
                }
                image.draw(in: NSRect(x: 16 + (index % 3) * 391, y: 16 + (index / 3) * 227, width: 375, height: 211),
                           from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true,
                           hints: [.interpolation: NSImageInterpolation.high])
            }
        }
        try sheet.write(to: output.appendingPathComponent("contact-sheet.png"), options: .atomic)
    } else {
        for (slug, data) in rendered {
            try require(data == bytes(output.appendingPathComponent("\(slug)/hero.png")), "Staged hero does not match renderer: \(slug)")
            try require(data == bytes(root.appendingPathComponent("content/images/\(slug)/hero.png")), "Installed hero does not match renderer: \(slug)")
        }
    }
    print("PASS (\(mode)): \(rendered.count) released heroes, 352px / 22% circular portraits; measured text bounds; empty/overflow metadata rejected")
    print("PASS: released drafts, referenced non-hero PNGs and canonical card copy unchanged; compact/card image orders preserved")
} catch {
    fputs("\(error)\n", stderr); exit(1)
}
