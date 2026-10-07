#!/usr/bin/env swift
// Native macOS renderer/checker. Run from the article root; no dependencies.
import AppKit
import CryptoKit

struct Failure: Error, CustomStringConvertible { let description: String }
func require(_ ok: Bool, _ message: String) throws {
    if !ok { throw Failure(description: message) }
}
let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath).standardizedFileURL
let title = "WHEN TO USE THIS"
let caption = "*Recognize the situation, then choose what to check.*"
let heading = "## When to use this"
let imagePattern = #"!\[([^\]\n]*)\]\(([^)\n]+)\)"#
let linkPattern = #"\[([^\]\n]*)\]\(([^)\n]+)\)"#
func matches(_ pattern: String, _ text: String) -> [NSTextCheckingResult] {
    try! NSRegularExpression(pattern: pattern).matches(in: text, range: NSRange(text.startIndex..., in: text))
}
func group(_ match: NSTextCheckingResult, _ index: Int, _ text: String) -> String {
    String(text[Range(match.range(at: index), in: text)!])
}
func replacing(_ pattern: String, _ text: String, _ replacement: String) -> String {
    try! NSRegularExpression(pattern: pattern).stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: replacement)
}
func words(_ text: String) -> Int { matches(#"[\p{L}\p{N}]+(?:[’'\-][\p{L}\p{N}]+)*"#, text).count }
func safe(_ base: URL, _ relative: String) throws -> URL {
    let url = base.appendingPathComponent(relative).standardizedFileURL
    try require(url.path.hasPrefix(base.path + "/"), "Unsafe path: \(relative)")
    try require(url.resolvingSymlinksInPath().path == url.path, "Symlink path rejected: \(url.path)")
    return url
}
func text(_ url: URL) throws -> String { try String(contentsOf: url, encoding: .utf8) }
func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
struct Bullet: Codable { let situation: String; let action: String }
func loadCopy(_ data: Data, _ slugs: [String]) throws -> [String: [Bullet]] {
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw Failure(description: "Copy must be a JSON object keyed by draft slug")
    }
    try require(Set(object.keys) == Set(slugs), "Copy must match released draft slugs exactly")
    for (slug, value) in object {
        try require(matches(#"^\d{2}-[a-z0-9]+(?:-[a-z0-9]+)*$"#, slug).count == 1, "Unsafe slug: \(slug)")
        guard let bullets = value as? [[String: Any]] else { throw Failure(description: "Malformed bullets: \(slug)") }
        try require((2...3).contains(bullets.count), "Expected 2–3 bullets: \(slug)")
        for bullet in bullets {
            try require(Set(bullet.keys) == ["situation", "action"], "Unexpected/missing fields: \(slug)")
            for field in ["situation", "action"] {
                guard let value = bullet[field] as? String else { throw Failure(description: "Non-string \(field): \(slug)") }
                try require(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && words(value) > 0,
                            "Empty \(field): \(slug)")
                try require(value == value.trimmingCharacters(in: .whitespacesAndNewlines) &&
                            value.rangeOfCharacter(from: .controlCharacters) == nil &&
                            value.rangeOfCharacter(from: CharacterSet(charactersIn: "[]<>\\`*_")) == nil,
                            "Unsafe/plain-text-only \(field): \(slug)")
            }
        }
    }
    let copy = try JSONDecoder().decode([String: [Bullet]].self, from: data)
    for slug in slugs {
        let count = words(copy[slug]!.map { $0.situation + " " + $0.action }.joined(separator: " "))
        try require((40...60).contains(count), "Card \(slug): \(count) words, expected 40–60")
    }
    return copy
}
func block(_ slug: String, _ bullets: [Bullet]) -> String {
    let alt = "When to use this: " + bullets.map { $0.situation + " → " + $0.action }.joined(separator: " ")
    return "\(heading)\n\n![\(alt)](../images/\(slug)/when-to-use.png)\n\n\(caption)\n\n"
}
func heroEnd(_ draft: String) throws -> String.Index {
    // A useful hero caption is optional; do not require an internal "Hero:" label.
    let pattern = #"\A# [^\n]+\n\n\*[^\n]+\*\n\n!\[[^\n]+\]\([^\n]+/hero\.png\)\n\n(?:\*[^\n*]+\*\n\n)?"#
    guard let match = matches(pattern, draft).first else { throw Failure(description: "Missing/malformed hero header") }
    return Range(match.range, in: draft)!.upperBound
}
func compactUse(_ draft: String) -> String? {
    let found = matches(#"(?m)^\*\*When to use this:\*\* [^\n]+\n\n"#, draft)
    guard found.count == 1, let match = found.first, let range = Range(match.range, in: draft) else { return nil }
    return String(draft[range])
}
func articleCount(_ draft: String, _ bullets: [Bullet]) -> Int {
    let visible = replacing(linkPattern, replacing(imagePattern, draft, ""), "$1")
    // Include all visible headings, subtitle, captions, tables, source labels, and CTA.
    // Exclude image alts/URLs; add raster heading and bullet copy exactly once.
    return words(visible) + (compactUse(draft) == nil ? words(title) + words(bullets.map { $0.situation + " " + $0.action }.joined(separator: " ")) : 0)
}
func validateDraft(_ draft: String, _ slug: String, _ bullets: [Bullet], rendering: Bool = false) throws -> Int {
    let end = try heroEnd(draft)
    let compact = compactUse(draft)
    if let compact = compact {
        try require(draft[end...].hasPrefix(compact) && !draft.contains(heading) && !draft.contains(caption), "\(slug): compact line misplaced or duplicated with a card")
    } else {
        try require(!draft.contains("**When to use this:**"), "\(slug): malformed/duplicate compact line")
        try require(draft[end...].hasPrefix(block(slug, bullets)), "\(slug): card misplaced or alt/caption differs from copy")
        try require(draft.components(separatedBy: heading).count == 2, "\(slug): duplicate/missing card heading")
    }
    let images = matches(imagePattern, draft)
    let names = compact == nil ? ["hero", "when-to-use", "step-1", "step-2", "step-3", "step-4"] : ["hero", "step-1", "step-2", "step-3", "step-4"]
    try require(images.map { group($0, 2, draft) } == names.map { "../images/\(slug)/\($0).png" },
                "\(slug): unexpected numbered-directory image references/order")
    for image in images { try require(words(group(image, 1, draft)) > 0, "\(slug): empty image alt") }
    for match in matches(linkPattern, draft) {
        let link = group(match, 2, draft)
        if link.hasPrefix("https://") || link.hasPrefix("mailto:") { continue } // Web/email targets are not local files; verify before publication.
        let url = try safe(root, "content/drafts/" + link)
        if rendering && link == "../images/\(slug)/when-to-use.png" { continue }
        try require(fm.fileExists(atPath: url.path), "\(slug): broken local link \(link)")
    }
    let count = articleCount(draft, bullets)
    try require((600...900).contains(count), "\(slug): \(count) reader-facing words, expected 600–900")
    return count
}

// Work in a 375-point layout at 2x. Body remains 17px at 375px display width.
let width: CGFloat = 375
let ink = NSColor(srgbRed: 0.06, green: 0.16, blue: 0.27, alpha: 1)
func attributed(_ string: String, bold: Bool, size: CGFloat) -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 3
    paragraph.lineBreakMode = .byWordWrapping
    return NSAttributedString(string: string, attributes: [.font: NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular),
                                                          .foregroundColor: ink, .paragraphStyle: paragraph])
}
func png(_ bullets: [Bullet], scale: CGFloat = 2) throws -> Data {
    var pieces: [(NSAttributedString, NSRect)] = []
    var y: CGFloat = 26
    func add(_ string: String, bold: Bool, size: CGFloat, x: CGFloat) throws {
        let attr = attributed(string, bold: bold, size: size)
        let available = width - 26 - x
        for word in string.split(separator: " ") {
            try require(attributed(String(word), bold: bold, size: size).size().width <= available,
                        "Unwrappable word: \(word)")
        }
        let box = attr.boundingRect(with: NSSize(width: available, height: .greatestFiniteMagnitude),
                                    options: [.usesLineFragmentOrigin, .usesFontLeading])
        let height = ceil(box.height) + 2
        pieces.append((attr, NSRect(x: x, y: y, width: available, height: height)))
        y += height
    }
    try add(title, bold: true, size: 18, x: 26)
    y += 23
    for (index, bullet) in bullets.enumerated() {
        let top = y
        try add(bullet.situation, bold: true, size: 17, x: 42)
        pieces.append((attributed("•", bold: true, size: 17), NSRect(x: 25, y: top, width: 14, height: 25)))
        y += 5
        try add("→ " + bullet.action, bold: false, size: 17, x: 42)
        if index < bullets.count - 1 { y += 22 }
    }
    let height = ceil(y + 26)
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
                                       bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                       colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else { throw Failure(description: "Cannot allocate card bitmap") }
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    let cg = context.cgContext
    cg.scaleBy(x: scale, y: scale)
    cg.translateBy(x: 0, y: height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    NSColor(srgbRed: 0.89, green: 0.95, blue: 1, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    for (attr, rect) in pieces { attr.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading]) }
    guard let data = bitmap.representation(using: .png, properties: [:]) else { throw Failure(description: "PNG encoding failed") }
    return data
}
func decode(_ data: Data, _ label: String) throws {
    try require(data.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]), "Not PNG: \(label)")
    guard let rep = NSBitmapImageRep(data: data), rep.pixelsWide > 0, rep.pixelsHigh > 0,
          rep.bitmapData != nil else { throw Failure(description: "PNG decode failed: \(label)") }
}

do {
    let args = CommandLine.arguments
    try require(args.count == 4 && ["render", "check"].contains(args[1]),
                "Usage: swift scripts/when-to-use.swift render|check SNAPSHOT /tmp/PREVIEW-DIR (run from article root)")
    let mode = args[1]
    let snapshot = URL(fileURLWithPath: args[2]).standardizedFileURL.resolvingSymlinksInPath()
    let preview = URL(fileURLWithPath: args[3]).standardizedFileURL
    let resolvedPreview = preview.resolvingSymlinksInPath()
    let tempRoots = [URL(fileURLWithPath: "/tmp").resolvingSymlinksInPath().path, URL(fileURLWithPath: NSTemporaryDirectory()).resolvingSymlinksInPath().path]
    try require(tempRoots.contains { resolvedPreview.path.hasPrefix($0.hasSuffix("/") ? $0 : $0 + "/") } &&
                !resolvedPreview.path.hasPrefix(snapshot.path + "/") && resolvedPreview.path != snapshot.path &&
                !resolvedPreview.path.hasPrefix(root.path + "/") && resolvedPreview.path != root.path,
                "Preview directory must be temporary and outside project/snapshot")
    let draftDir = try safe(root, "content/drafts")
    let slugs = try fm.contentsOfDirectory(atPath: draftDir.path).filter { $0.hasSuffix(".md") }.sorted().map { String($0.dropLast(3)) }
    try require(slugs.count == 4, "Expected exactly four released drafts")
    let copy = try loadCopy(Data(contentsOf: safe(root, "content/when-to-use.json")), slugs)
    var oldManifest = ""
    var oldCount = 0
    // Both modes verify the immutable images before writing anything.
    for slug in slugs {
        for name in ["hero", "step-1", "step-2", "step-3", "step-4"] {
            let relative = "content/images/\(slug)/\(name).png"
            let current = try Data(contentsOf: safe(root, relative))
            let before = try Data(contentsOf: safe(snapshot, relative))
            try require(current == before, "Pre-existing image changed: \(relative)")
            try decode(current, relative)
            oldManifest += "\(digest(current))  \(relative)\n"
            oldCount += 1
        }
    }
    // Preflight every draft/card before render writes; range errors cannot leave a partial batch.
    var drafts: [String: String] = [:]
    var cards: [String: Data] = [:]
    for slug in slugs {
        var draft = try text(safe(root, "content/drafts/\(slug).md"))
        if compactUse(draft) != nil {
            _ = try validateDraft(draft, slug, copy[slug]!)
            continue // Plain-text use lines must never regain a raster card.
        }
        if mode == "render" {
            let end = try heroEnd(draft)
            if draft[end...].hasPrefix(heading + "\n\n") {
                let tail = String(draft[end...])
                let cardPattern = #"\A## When to use this\n\n!\[[^\n]+\]\([^\n]+/when-to-use\.png\)\n\n\*[^\n]+\*\n\n"#
                guard let match = matches(cardPattern, tail).first else { throw Failure(description: "Malformed existing card: \(slug)") }
                draft = String(draft[..<end]) + block(slug, copy[slug]!) + String(tail[Range(match.range, in: tail)!.upperBound...])
            } else { draft.insert(contentsOf: block(slug, copy[slug]!), at: end) }
        }
        _ = try validateDraft(draft, slug, copy[slug]!, rendering: mode == "render")
        drafts[slug] = draft
        cards[slug] = try png(copy[slug]!)
    }
    try fm.createDirectory(at: resolvedPreview, withIntermediateDirectories: true)
    for slug in slugs {
        guard drafts[slug] != nil else { continue }
        let cardURL = try safe(root, "content/images/\(slug)/when-to-use.png")
        if mode == "render" {
            try cards[slug]!.write(to: cardURL, options: .atomic)
            try drafts[slug]!.write(to: safe(root, "content/drafts/\(slug).md"), atomically: true, encoding: .utf8)
        }
        let actual = try Data(contentsOf: cardURL)
        try decode(actual, slug)
        try require(actual == cards[slug]!, "\(slug): image/text mismatch; rerender from canonical JSON on this macOS/font stack")
        let count = try validateDraft(drafts[slug]!, slug, copy[slug]!)
        // Scale the ACTUAL exported PNG, not a fresh text layout, to a 375px preview.
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        let mobile = try safe(resolvedPreview, slug + "-375.png")
        task.arguments = ["--resampleWidth", "375", cardURL.path, "--out", mobile.path]
        task.standardOutput = FileHandle.nullDevice
        try task.run(); task.waitUntilExit()
        try require(task.terminationStatus == 0, "Mobile preview failed: \(slug)")
        try decode(Data(contentsOf: mobile), mobile.path)
        print("\(slug): \(count) words; PNG + six links + placement + equivalent alt PASS; preview \(mobile.path)")
    }
    try oldManifest.write(to: safe(resolvedPreview, "old-png-sha256.txt"), atomically: true, encoding: .utf8)
    print("PASS: \(cards.count) cards; compact text retained; \(oldCount) old PNGs decoded and byte-identical to snapshot")
    print("Old-image manifest SHA256: \(digest(Data(oldManifest.utf8)))")
} catch {
    fputs("FAIL: \(error)\n", stderr)
    exit(1)
}
