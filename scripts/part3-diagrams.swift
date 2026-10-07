// Invoked through part3-assets.py with the canonical hero/text/PNG helpers.
let ink = NSColor(srgbRed: 0.055, green: 0.15, blue: 0.24, alpha: 1)
let paper = NSColor(srgbRed: 0.97, green: 0.985, blue: 1, alpha: 1)
let blueFill = NSColor(srgbRed: 0.80, green: 0.92, blue: 1, alpha: 1)
let warmFill = NSColor(srgbRed: 1, green: 0.87, blue: 0.76, alpha: 1)
let blueLine = NSColor(srgbRed: 0.08, green: 0.39, blue: 0.65, alpha: 1)
let orangeLine = NSColor(srgbRed: 0.69, green: 0.25, blue: 0.06, alpha: 1)

func say(_ value: String, _ rect: NSRect, size: CGFloat = 76, color: NSColor = ink,
         centered: Bool = false, pageHeight: CGFloat = 900) throws {
    let label = NSMutableAttributedString(attributedString: try text(value, size: size, color: color, bold: true))
    let style = NSMutableParagraphStyle(); style.lineBreakMode = .byWordWrapping
    style.alignment = centered ? .center : .left
    label.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: label.length))
    try require(rect.minX >= 0 && rect.minY >= 0 && rect.maxX <= 1600 && rect.maxY <= pageHeight,
                "Label outside canvas: \(value)")
    let h = try height(label, width: rect.width)
    try require(h <= rect.height, "Label needs \(h)px, has \(rect.height)px: \(value)")
    label.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}
func box(_ value: String, _ rect: NSRect, _ fill: NSColor, size: CGFloat = 70, pageHeight: CGFloat = 900) throws {
    let path = NSBezierPath(roundedRect: rect, xRadius: 24, yRadius: 24)
    fill.setFill(); path.fill(); ink.withAlphaComponent(0.25).setStroke(); path.lineWidth = 3; path.stroke()
    let inner = rect.insetBy(dx: 18, dy: 18)
    let h = try height(text(value, size: size, color: ink, bold: true), width: inner.width)
    try require(h <= inner.height, "Box text overflows: \(value)")
    try say(value, NSRect(x: inner.minX, y: rect.midY - h / 2, width: inner.width, height: h + 1),
            size: size, centered: true, pageHeight: pageHeight)
}
func arrow(_ start: CGFloat, _ end: CGFloat, _ y: CGFloat) throws {
    try require(end - start >= 24, "Arrow gap too small")
    ink.setStroke(); let path = NSBezierPath(); path.lineWidth = 4
    path.move(to: NSPoint(x: start + 3, y: y)); path.line(to: NSPoint(x: end - 6, y: y))
    path.move(to: NSPoint(x: end - 18, y: y - 10)); path.line(to: NSPoint(x: end - 6, y: y))
    path.line(to: NSPoint(x: end - 18, y: y + 10)); path.stroke()
}
func background(_ h: CGFloat = 900) {
    paper.setFill(); NSRect(x: 0, y: 0, width: 1600, height: h).fill()
    blueLine.withAlphaComponent(0.07).setStroke(); let grid = NSBezierPath(); grid.lineWidth = 1
    for x in stride(from: 0, through: 1600, by: 80) {
        grid.move(to: NSPoint(x: x, y: 0)); grid.line(to: NSPoint(x: CGFloat(x), y: h))
    }
    for y in stride(from: CGFloat(0), through: h, by: 80) {
        grid.move(to: NSPoint(x: 0, y: y)); grid.line(to: NSPoint(x: 1600, y: y))
    }
    grid.stroke()
}
func boundary(_ x: CGFloat, from y1: CGFloat, to y2: CGFloat, color: NSColor) {
    color.setStroke(); let path = NSBezierPath(); path.lineWidth = 7
    path.setLineDash([14, 10], count: 2, phase: 0)
    path.move(to: NSPoint(x: x, y: y1)); path.line(to: NSPoint(x: x, y: y2)); path.stroke()
}
func requestRow(_ time: String, y: CGFloat, reordered: Bool) throws {
    let firstWidth: CGFloat = reordered ? 720 : 320
    let secondX: CGFloat = reordered ? 840 : 440
    let secondWidth: CGFloat = reordered ? 320 : 720
    try box(reordered ? "Shared\ninstructions" : time, NSRect(x: 80, y: y, width: firstWidth, height: 210), reordered ? blueFill : warmFill)
    try box(reordered ? time : "Shared\ninstructions", NSRect(x: secondX, y: y, width: secondWidth, height: 210), reordered ? warmFill : blueFill)
    try box("User\nquestion", NSRect(x: 1200, y: y, width: 320, height: 210), .white)
    try arrow(80 + firstWidth, secondX, y + 105); try arrow(1160, 1200, y + 105)
}
func diagram(_ step: Int) throws -> Data {
    try require((1...4).contains(step), "Unknown diagram step")
    return try png {
        background()
        let titles = [1: "1 · Mostly the same prompt", 2: "2 · No skipping the mismatch",
                      3: "3 · Put the stable block first", 4: "4 · Measure the actual result"]
        guard let title = titles[step] else { throw Failure(message: "Missing step title") }
        try say(title, NSRect(x: 80, y: 55, width: 1440, height: 130), size: 80)
        if step <= 3 {
            try requestRow("09:00", y: 220, reordered: step == 3)
            try requestRow("09:01", y: 480, reordered: step == 3)
            if step == 2 { boundary(420, from: 195, to: 715, color: orangeLine) }
            if step == 3 { boundary(820, from: 195, to: 705, color: blueLine) }
            let note: String
            switch step {
            case 1: note = "The question stays in its user role."
            case 2: note = "New prefix → new work for the later block."
            default: note = "Mark the stable cache boundary.\nEligible does not mean guaranteed."
            }
            try say(note, NSRect(x: 80, y: step == 3 ? 718 : 770, width: 1440, height: step == 3 ? 175 : 100), size: 70)
        } else {
            try box("Cache\nreads", NSRect(x: 80, y: 240, width: 700, height: 230), blueFill, size: 80)
            try box("First-token\nlatency", NSRect(x: 820, y: 240, width: 700, height: 230), blueFill, size: 80)
            try box("Total\ncost", NSRect(x: 80, y: 500, width: 700, height: 230), warmFill, size: 80)
            try box("Task\nquality", NSRect(x: 820, y: 500, width: 700, height: 230), warmFill, size: 80)
            try say("Same workload. Compare both layouts.", NSRect(x: 80, y: 780, width: 1440, height: 100), size: 70)
        }
    }
}
func posterRow(y: CGFloat, reordered: Bool) throws {
    let firstWidth: CGFloat = reordered ? 640 : 360
    let secondX: CGFloat = reordered ? 760 : 480
    let secondWidth: CGFloat = reordered ? 360 : 640
    try box(reordered ? "Shared\ninstructions" : "Time\nchanges", NSRect(x: 80, y: y, width: firstWidth, height: 230),
            reordered ? blueFill : warmFill, size: 74, pageHeight: 2000)
    try box(reordered ? "Time\nchanges" : "Shared\ninstructions", NSRect(x: secondX, y: y, width: secondWidth, height: 230),
            reordered ? warmFill : blueFill, size: 74, pageHeight: 2000)
    try box("User\nquestion", NSRect(x: 1160, y: y, width: 360, height: 230), .white, size: 74, pageHeight: 2000)
    try arrow(80 + firstWidth, secondX, y + 115); try arrow(1120, 1160, y + 115)
    boundary(reordered ? 740 : 460, from: y - 18, to: y + 248, color: reordered ? blueLine : orangeLine)
}
func poster(_ title: String, portrait: NSImage) throws -> Data {
    return try png(width: 1600, height: 2000) {
        background(2000)
        ink.setFill(); NSRect(x: 0, y: 0, width: 1600, height: 525).fill()
        try say("AI ENGINEERING FUNDAMENTALS · 03", NSRect(x: 80, y: 48, width: 1440, height: 60), size: 40, color: cyan, pageHeight: 2000)
        try say(title, NSRect(x: 80, y: 137, width: 990, height: 365), size: 96, color: white, pageHeight: 2000)
        let photoRect = NSRect(x: 1136, y: 115, width: 352, height: 352)
        NSGraphicsContext.saveGraphicsState(); NSBezierPath(ovalIn: photoRect).addClip()
        portrait.draw(in: photoRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
        NSGraphicsContext.restoreGraphicsState()
        cyan.setStroke(); let ring = NSBezierPath(ovalIn: photoRect); ring.lineWidth = 5; ring.stroke()
        try say("BEFORE · early timestamp", NSRect(x: 80, y: 580, width: 1440, height: 105), size: 80, color: orangeLine, pageHeight: 2000)
        try posterRow(y: 715, reordered: false)
        try say("New time → different prefix.\nLater text cannot reuse its old state.", NSRect(x: 80, y: 985, width: 1440, height: 175), size: 70, pageHeight: 2000)
        try say("AFTER · stable content first", NSRect(x: 80, y: 1200, width: 1440, height: 105), size: 80, color: blueLine, pageHeight: 2000)
        try posterRow(y: 1335, reordered: true)
        try say("Put cache boundary after stable content.\nEligible reuse is not a guaranteed hit.", NSRect(x: 80, y: 1605, width: 1440, height: 175), size: 70, pageHeight: 2000)
        blueLine.withAlphaComponent(0.3).setFill(); NSRect(x: 80, y: 1790, width: 1440, height: 3).fill()
        try say("Keep roles. Test behavior. Measure results.", NSRect(x: 80, y: 1820, width: 1440, height: 90), size: 70, pageHeight: 2000)
        try say("Idan Bar · bar.idan@gmail.com", NSRect(x: 80, y: 1910, width: 1440, height: 80), size: 64, pageHeight: 2000)
    }
}
func mobile(_ data: Data, width: Int = 375) throws -> Data {
    guard let rep = NSBitmapImageRep(data: data), let image = NSImage(data: data), rep.pixelsWide > 0 else {
        throw Failure(message: "Invalid preview source")
    }
    let h = Int((Double(width) * Double(rep.pixelsHigh) / Double(rep.pixelsWide)).rounded())
    return try png(width: width, height: h) {
        image.draw(in: NSRect(x: 0, y: 0, width: width, height: h), from: .zero, operation: .sourceOver,
                   fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    }
}

do {
    let args = CommandLine.arguments
    try require(args.count == 2, "Expected one staging directory")
    let output = URL(fileURLWithPath: args[1]).standardizedFileURL.resolvingSymlinksInPath()
    try require(output != root && output != root.appendingPathComponent("content") &&
                !output.path.hasPrefix(root.appendingPathComponent("content").path + "/"), "Unsafe staging directory")
    let slug = "09-prefix-caching"
    try require(try publicationLabel(slug) == "03", "Source 09 must be publication Part 3")
    let draft = try String(contentsOf: root.appendingPathComponent("content/drafts/\(slug).md"), encoding: .utf8)
    let (title, promise) = try metadata(draft, slug: slug)
    let reference = root.appendingPathComponent("content/portrait.png")
    guard let portrait = NSImage(contentsOf: reference), let cg = portrait.cgImage(forProposedRect: nil, context: nil, hints: nil),
          cg.width == 680 && cg.height == 680 else {
        throw Failure(message: "Invalid approved portrait")
    }
    var rendered = ["hero": try hero(title, promise, slug: slug, portrait: portrait), "poster": try poster(title, portrait: portrait)]
    for step in 1...4 { rendered["step-\(step)"] = try diagram(step) }
    var rejected = false
    do { _ = try diagram(0) } catch { rejected = true }
    try require(rejected, "Invalid diagram accepted")
    rejected = false
    do { _ = try height(text("", size: 70, color: ink), width: 100) } catch { rejected = true }
    try require(rejected, "Empty label accepted")
    rejected = false
    do { _ = try height(text(String(repeating: "W", count: 200), size: 70, color: ink), width: 100) } catch { rejected = true }
    try require(rejected, "Unwrappable label accepted")
    rejected = false
    do { _ = try png { try say("Clipped", NSRect(x: 80, y: 80, width: 400, height: 1)) } } catch { rejected = true }
    try require(rejected, "Clipped label accepted")
    rejected = false
    do { _ = try png { try say("Outside", NSRect(x: 80, y: 890, width: 400, height: 100)) } } catch { rejected = true }
    try require(rejected, "Out-of-canvas label accepted")
    try fm.createDirectory(at: output.appendingPathComponent("mobile"), withIntermediateDirectories: true)
    for (name, data) in rendered {
        try data.write(to: output.appendingPathComponent(name + ".png"), options: .atomic)
        try mobile(data).write(to: output.appendingPathComponent("mobile/" + name + ".png"), options: .atomic)
    }
    let card = try Data(contentsOf: root.appendingPathComponent("content/images/\(slug)/when-to-use.png"))
    try mobile(card).write(to: output.appendingPathComponent("mobile/when-to-use.png"), options: .atomic)
    if let heroData = rendered["hero"] {
        try mobile(heroData, width: 240).write(to: output.appendingPathComponent("hero-thumbnail.png"), options: .atomic)
    } else { throw Failure(message: "Hero not rendered") }
    print("PASS: staged one 1600×900 hero, four 1600×900 diagrams, one 1600×2000 poster; seven actual 375px previews")
    print("PASS: canonical 352px portrait; measured labels; invalid step, empty, unwrappable, clipped and out-of-canvas label checks")
} catch {
    fputs("\(error)\n", stderr); exit(1)
}
