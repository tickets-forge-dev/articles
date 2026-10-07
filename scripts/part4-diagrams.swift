// Run via part4-assets.py; uses the shared measured drawing/hero helpers.
struct Part4Measurement: Decodable {
    let correct: Int
    let scoredDecisions: Int
    let medianBatchS: Double
    let estimatedUsdPer100Queries: Double
}
struct Part4Results: Decodable {
    let arms: [String: Part4Measurement]
}
let part4Models = ["jev-1.13.0", "gpt-5.6-luna", "gpt-5.6-sol"]
func downArrow(_ x: CGFloat, _ start: CGFloat, _ end: CGFloat) throws {
    try require(end - start >= 24, "Vertical arrow too short")
    ink.setStroke(); let p = NSBezierPath(); p.lineWidth = 4
    p.move(to: NSPoint(x: x, y: start)); p.line(to: NSPoint(x: x, y: end - 5))
    p.move(to: NSPoint(x: x - 10, y: end - 18)); p.line(to: NSPoint(x: x, y: end - 5))
    p.line(to: NSPoint(x: x + 10, y: end - 18)); p.stroke()
}
func part4Table(_ results: Part4Results, y: CGFloat, pageHeight: CGFloat = 900) throws {
    let columns: [(CGFloat, CGFloat)] = [(80, 390), (490, 290), (800, 290), (1110, 410)]
    for (index, label) in ["Model", "Correct", "Time /10", "USD /100"].enumerated() {
        try say(label, NSRect(x: columns[index].0, y: y, width: columns[index].1, height: 85), size: 62, color: blueLine, pageHeight: pageHeight)
    }
    for (index, model) in part4Models.enumerated() {
        guard let arm = results.arms[model] else { throw Failure(message: "Missing measured model: \(model)") }
        let rowY = y + 110 + CGFloat(index) * 130
        let fill = index == 0 ? blueFill : NSColor.white
        fill.setFill(); NSRect(x: 70, y: rowY - 6, width: 1460, height: 118).fill()
        let labels = [index == 0 ? "Jev 1.13.0" : (index == 1 ? "5.6-Luna*" : "5.6-Sol*"),
                      "\(arm.correct)/\(arm.scoredDecisions)", String(format: "%.3f s", arm.medianBatchS),
                      String(format: "$%.5f", arm.estimatedUsdPer100Queries)]
        for (column, label) in labels.enumerated() {
            try say(label, NSRect(x: columns[column].0, y: rowY + 10, width: columns[column].1, height: 95), size: 70, pageHeight: pageHeight)
        }
    }
}
func part4Diagram(_ step: Int, results: Part4Results) throws -> Data {
    let titles = [1: "1 · A label, not an action", 2: "2 · Compare the same job",
                  3: "3 · Jev answers a Choice", 4: "4 · Compare all three outcomes"]
    guard let title = titles[step] else { throw Failure(message: "Unknown Part 4 step") }
    return try png {
        background()
        try say(title, NSRect(x: 80, y: 55, width: 1440, height: 130), size: 80)
        switch step {
        case 1:
            try box("Customer\ntext", NSRect(x: 80, y: 250, width: 440, height: 240), blueFill, size: 80)
            try arrow(520, 580, 370)
            try box("General\nLLM", NSRect(x: 580, y: 250, width: 440, height: 240), warmFill, size: 80)
            try arrow(1020, 1080, 370)
            try box("One of\ntwo labels", NSRect(x: 1080, y: 250, width: 440, height: 240), blueFill, size: 76)
            try say("Close account? Or a different request?", NSRect(x: 80, y: 600, width: 1440, height: 110), size: 70)
            try say("No reply. No account-closure action.", NSRect(x: 80, y: 785, width: 1440, height: 100), size: 70)
        case 2:
            try box("Same text + same two-label rubric", NSRect(x: 80, y: 210, width: 1440, height: 150), blueFill, size: 74)
            for (index, label) in ["Jev", "5.6-Luna", "5.6-Sol"].enumerated() {
                try box(label, NSRect(x: 80 + CGFloat(index) * 500, y: 440, width: 440, height: 160), index == 0 ? warmFill : blueFill, size: 76)
            }
            try say("40 calibration → freeze policy", NSRect(x: 80, y: 655, width: 1440, height: 95), size: 74)
            try say("60 held-out · batches of 10 · 3 passes", NSRect(x: 80, y: 785, width: 1440, height: 100), size: 70)
        case 3:
            try box("Query + label\ndefinitions", NSRect(x: 80, y: 210, width: 740, height: 230), blueFill, size: 76)
            try arrow(820, 920, 325)
            try box("Jev\nChoice", NSRect(x: 920, y: 210, width: 600, height: 230), warmFill, size: 80)
            ink.setStroke(); let p = NSBezierPath(); p.lineWidth = 4
            p.move(to: NSPoint(x: 1220, y: 440)); p.line(to: NSPoint(x: 1220, y: 500))
            p.move(to: NSPoint(x: 430, y: 500)); p.line(to: NSPoint(x: 1220, y: 500)); p.stroke()
            for x in [CGFloat(430), 1150] { try downArrow(x, 500, 565) }
            try box("closure_request", NSRect(x: 80, y: 565, width: 700, height: 160), blueFill, size: 70)
            try box("not_closure", NSRect(x: 820, y: 565, width: 700, height: 160), blueFill, size: 70)
            try say("Recommendation only. Human review.", NSRect(x: 80, y: 785, width: 1440, height: 100), size: 70)
        default:
            try say("60 unique queries · 3 passes per model", NSRect(x: 80, y: 185, width: 1440, height: 85), size: 64)
            try part4Table(results, y: 280)
            try say("*GPT-5.6 via Codex · USD are estimates", NSRect(x: 80, y: 785, width: 1440, height: 85), size: 62)
        }
    }
}
func part4Poster(_ title: String, portrait: NSImage, results: Part4Results) throws -> Data {
    guard let icon = NSImage(contentsOf: root.appendingPathComponent("artifacts/article-series/part-4/sources/typesafe-icon.png")),
          let bitmap = icon.cgImage(forProposedRect: nil, context: nil, hints: nil),
          bitmap.width >= 112, bitmap.width == bitmap.height,
          let jev = results.arms[part4Models[0]], let luna = results.arms[part4Models[1]] else {
        throw Failure(message: "Missing icon or measured comparison")
    }
    return try png(width: 1600, height: 2000) {
        background(2000)
        ink.setFill(); NSRect(x: 0, y: 0, width: 1600, height: 525).fill()
        try say("AI ENGINEERING FUNDAMENTALS · 04", NSRect(x: 80, y: 48, width: 1440, height: 60), size: 40, color: cyan, pageHeight: 2000)
        try say(title, NSRect(x: 80, y: 137, width: 990, height: 365), size: 96, color: white, pageHeight: 2000)
        let photo = NSRect(x: 1136, y: 115, width: 352, height: 352)
        NSGraphicsContext.saveGraphicsState(); NSBezierPath(ovalIn: photo).addClip()
        portrait.draw(in: photo, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
        NSGraphicsContext.restoreGraphicsState(); cyan.setStroke()
        let ring = NSBezierPath(ovalIn: photo); ring.lineWidth = 5; ring.stroke()
        try say("MEASURED · ACCOUNT-CLOSURE INTENT", NSRect(x: 80, y: 580, width: 1440, height: 90), size: 62, color: blueLine, pageHeight: 2000)
        try part4Table(results, y: 705, pageHeight: 2000)
        try say(String(format: "%.2f× faster than Luna*", luna.medianBatchS / jev.medianBatchS), NSRect(x: 80, y: 1250, width: 1440, height: 130), size: 96, pageHeight: 2000)
        try say(String(format: "%.2f%% lower price equivalent*", 100 * (1 - jev.estimatedUsdPer100Queries / luna.estimatedUsdPer100Queries)), NSRect(x: 80, y: 1385, width: 1440, height: 105), size: 80, pageHeight: 2000)
        icon.draw(in: NSRect(x: 80, y: 1540, width: 112, height: 112), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
        try say("Classify intent. Humans review.", NSRect(x: 224, y: 1540, width: 1296, height: 150), size: 68, pageHeight: 2000)
        try say("*LLMs via Codex. API rates, not invoices.", NSRect(x: 80, y: 1740, width: 1440, height: 90), size: 62, pageHeight: 2000)
        try say("60 unique queries. Three passes per model.", NSRect(x: 80, y: 1840, width: 1440, height: 90), size: 62, pageHeight: 2000)
        try say("Same sample accuracy. No actions executed.", NSRect(x: 80, y: 1920, width: 1440, height: 75), size: 60, pageHeight: 2000)
    }
}

do {
    let args = CommandLine.arguments
    try require(args.count == 2, "Expected staging directory")
    let output = URL(fileURLWithPath: args[1]).standardizedFileURL.resolvingSymlinksInPath()
    try require(output != root && output != root.appendingPathComponent("content") && !output.path.hasPrefix(root.appendingPathComponent("content").path + "/"), "Unsafe output")
    let slug = "08-retrieval-pipeline"
    try require(try publicationLabel(slug) == "04", "Incorrect publication identity")
    let draft = try String(contentsOf: root.appendingPathComponent("content/drafts/\(slug).md"), encoding: .utf8)
    let (title, promise) = try metadata(draft, slug: slug)
    let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
    let results = try decoder.decode(Part4Results.self, from: Data(contentsOf: root.appendingPathComponent("artifacts/article-series/part-4-coding/account-closure-comparison-2026-10-04/summary.json")))
    try require(part4Models.allSatisfy { results.arms[$0]?.correct == 180 && results.arms[$0]?.scoredDecisions == 180 }, "Expected complete measured evaluation")
    guard let portrait = NSImage(contentsOf: root.appendingPathComponent("content/portrait.png")),
          let cg = portrait.cgImage(forProposedRect: nil, context: nil, hints: nil), cg.width == 680, cg.height == 680 else {
        throw Failure(message: "Invalid approved portrait")
    }
    var images = ["hero": try hero(title, promise, slug: slug, portrait: portrait), "poster": try part4Poster(title, portrait: portrait, results: results)]
    for step in 1...4 { images["step-\(step)"] = try part4Diagram(step, results: results) }
    var rejected = false
    do { _ = try part4Diagram(0, results: results) } catch { rejected = true }
    try require(rejected, "Invalid step accepted")
    try fm.createDirectory(at: output.appendingPathComponent("mobile"), withIntermediateDirectories: true)
    for (name, data) in images {
        try data.write(to: output.appendingPathComponent(name + ".png"), options: .atomic)
        try mobile(data).write(to: output.appendingPathComponent("mobile/" + name + ".png"), options: .atomic)
    }
    guard let heroData = images["hero"] else { throw Failure(message: "Missing hero") }
    try mobile(heroData, width: 240).write(to: output.appendingPathComponent("hero-thumbnail.png"), options: .atomic)
    print("PASS: Part 4 hero, four diagrams and measured poster staged; labels bounded; 375px exports; invalid step rejected")
} catch { fputs("\(error)\n", stderr); exit(1) }
