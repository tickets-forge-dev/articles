#!/usr/bin/env python3
"""Check current draft layouts/counts and optional hero-caption handling on macOS.
Run: python3 scripts/check-draft-layout.py
Reuses the canonical Swift helpers without their snapshot-dependent card CLI.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
source = (root / 'scripts/when-to-use.swift').read_text()
marker = '\ndo {\n    let args = CommandLine.arguments'
if source.count(marker) != 1:
    raise ValueError('Cannot locate the canonical checker entry point')
helpers = source.split(marker, 1)[0]
checks = r'''
do {
    let directory = root.appendingPathComponent("content/drafts")
    let slugs = try fm.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".md") }.sorted().map { String($0.dropLast(3)) }
    try require(slugs.count == 4, "Expected the four released drafts")
    let copy = try loadCopy(Data(contentsOf: root.appendingPathComponent("content/when-to-use.json")), slugs)
    for slug in slugs {
        guard let bullets = copy[slug] else { throw Failure(description: "Missing card copy") }
        let draft = try text(directory.appendingPathComponent(slug + ".md"))
        print("\(slug): \(try validateDraft(draft, slug, bullets)) words; layout PASS")
    }
    let slug = "01-prompt-to-answer"
    guard let bullets = copy[slug] else { throw Failure(description: "Missing test card copy") }
    let original = try text(directory.appendingPathComponent(slug + ".md"))
    let captionPattern = #"\*Hero: [^\n]+\*\n\n"#
    try require(matches(captionPattern, original).count == 1, "Test fixture must have one legacy hero caption")
    let noCaption = replacing(captionPattern, original, "")
    let naturalCaption = replacing(captionPattern, original, "*One request, several engineering stages.*\n\n")
    for draft in [original, noCaption, naturalCaption] {
        _ = try validateDraft(draft, slug, bullets)
    }
    for bad in ["", original.replacingOccurrences(of: "# What Happens", with: "What Happens"),
                original.replacingOccurrences(of: "/hero.png", with: "/missing.png"),
                noCaption.replacingOccurrences(of: heading + "\n\n", with: ""),
                noCaption.replacingOccurrences(of: heading + "\n\n", with: "Unexpected prose.\n\n" + heading + "\n\n")] {
        var rejected = false
        do { _ = try validateDraft(bad, slug, bullets) } catch { rejected = true }
        try require(rejected, "Malformed layout accepted")
    }
    let compact = "**When to use this:** Your AI must apply policy exceptions or handle uncertain evidence.\n\n"
    let compactDraft = noCaption.replacingOccurrences(of: block(slug, bullets), with: compact)
    _ = try validateDraft(compactDraft, slug, bullets)
    let visible = replacing(linkPattern, replacing(imagePattern, compactDraft, ""), "$1")
    try require(articleCount(compactDraft, bullets) == words(visible), "Obsolete card copy still counted")
    for bad in [compactDraft.replacingOccurrences(of: compact, with: compact + compact),
                compactDraft.replacingOccurrences(of: compact, with: "Unexpected prose.\n\n" + compact),
                compactDraft.replacingOccurrences(of: "/step-1.png", with: "/missing.png"),
                compactDraft.replacingOccurrences(of: compact, with: compact + block(slug, bullets))] {
        var rejected = false
        do { _ = try validateDraft(bad, slug, bullets) } catch { rejected = true }
        try require(rejected, "Invalid compact layout accepted")
    }
    print("PASS: card and compact layouts; exact visible word counts; malformed, duplicate, misplaced and missing-image fixtures rejected")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
'''
with tempfile.TemporaryDirectory(prefix='draft-layout-') as temporary:
    script = Path(temporary) / 'check.swift'
    script.write_text(helpers + checks)
    subprocess.run(['swift', str(script)], cwd=root, check=True)
