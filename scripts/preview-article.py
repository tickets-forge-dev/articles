#!/usr/bin/env python3
"""Create a self-contained local reading preview; does not publish anything.
Run: uv run --with markdown==3.9 --no-project python scripts/preview-article.py [PART]
PART selects content/publication-order.json, default 1. Use --draft-number N for
an original draft number instead. The draft must contain the approved email CTA.
"""
import argparse
import base64
import html
import json
import os
from pathlib import Path
import re
from urllib.parse import quote, unquote, urlsplit, urlunsplit

import markdown

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('number', type=int, nargs='?', choices=range(1, 16))
parser.add_argument('--draft-number', type=int, choices=range(1, 16))
args = parser.parse_args()
if args.number is not None and args.draft_number is not None:
    parser.error('Choose a publication part OR --draft-number, not both')
root = Path(__file__).resolve().parent.parent
if args.draft_number is not None:
    candidates = list((root / 'content/drafts').glob(f'{args.draft_number:02}-*.md'))
    if len(candidates) != 1:
        raise ValueError(f'Expected exactly one draft for original number {args.draft_number}')
    draft = next(iter(candidates))
    output_name = f'draft-{args.draft_number}.html'
else:
    order = json.loads((root / 'content/publication-order.json').read_text())
    if (not isinstance(order, list) or not order or
            any(not isinstance(slug, str) or not re.fullmatch(r'[0-9]{2}-[a-z0-9-]+', slug)
                for slug in order) or len(set(order)) != len(order)):
        raise ValueError('Malformed or duplicate publication slugs')
    part = args.number if args.number is not None else 1
    if part > len(order):
        parser.error(f'Publication Part {part} has not been assigned; use --draft-number for original drafts')
    draft = root / 'content/drafts' / (order[part - 1] + '.md')
    output_name = f'article-{part}.html'
if not draft.resolve().is_relative_to((root / 'content/drafts').resolve()):
    raise ValueError('Draft must stay within content/drafts')
asset_root = (root / 'content/images' / draft.stem).resolve()
source = draft.read_text()
first_line = source.partition('\n')[0]
if not first_line.startswith('# ') or not first_line[2:].strip():
    raise ValueError('Expected a nonempty article title')
title = html.escape(first_line[2:])
body = markdown.markdown(source, extensions=['tables'])
preview_directory = root / 'artifacts/article-series/preview'


def local_link(match):
    url = urlsplit(html.unescape(match.group(1)))
    if url.scheme or url.netloc or not url.path:
        return match.group(0)
    path = (draft.parent / unquote(url.path)).resolve()
    if not path.is_relative_to(root) or not path.is_file():
        raise ValueError(f'Missing or unsafe local evidence link: {path}')
    relative = quote(os.path.relpath(path, preview_directory), safe='/')
    return 'href="' + html.escape(urlunsplit(('', '', relative, url.query, url.fragment)), quote=True) + '"'


body = re.sub(r'href="([^"]+)"', local_link, body)


def embed(match):
    path = (draft.parent / html.unescape(match.group(1))).resolve()
    if not path.is_relative_to(asset_root) or path.suffix != '.png':
        raise ValueError(f'Unexpected image path: {path}')
    data = path.read_bytes()
    if not data.startswith(b'\x89PNG\r\n\x1a\n'):
        raise ValueError(f'Not a PNG: {path}')
    return 'src="data:image/png;base64,' + base64.b64encode(data).decode() + '"'


body, count = re.subn(r'src="([^"]+)"', embed, body)
compact_lines = re.findall(r'(?m)^\*\*When to use this:\*\* [^\n]+\n\n', source)
compact = len(compact_lines) == 1
names = ['hero', *([] if compact else ['when-to-use']), 'step-1', 'step-2', 'step-3', 'step-4']
expected = [f'../images/{draft.stem}/{name}.png' for name in names]
if (re.findall(r'!\[[^\]\n]*\]\(([^)\n]+)\)', source) != expected or
        count != len(names) or 'href="mailto:bar.idan@gmail.com"' not in body):
    raise ValueError('Expected ordered article images and the approved email CTA')
# A simple readable preview, not a claim to reproduce Medium’s exact rendering.
page = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>'''+title+'''</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#fff;color:#202124;font:20px/1.65 Georgia,serif}
.preview{padding:12px 20px;text-align:center;background:#edf6fc;color:#314b60;font:14px/1.5 system-ui,sans-serif}
article{max-width:800px;margin:40px auto 80px;padding:0 24px}h1,h2{font-family:system-ui,sans-serif;line-height:1.2;color:#111}
h1{font-size:44px;letter-spacing:-1.3px;margin-bottom:16px}h2{font-size:28px;margin-top:44px}
h1+p{font:22px/1.5 system-ui,sans-serif;color:#626a73}h1+p em{font-style:normal}
p{margin:22px 0}img{display:block;max-width:100%;height:auto;margin:28px auto 0}
p:has(>img)+p:has(>em:only-child){font:15px/1.5 system-ui,sans-serif;color:#67717b;margin-top:10px}
a{color:#087096;text-underline-offset:3px}li{margin:10px 0}code{font-size:.88em;background:#f2f4f5;padding:2px 4px;overflow-wrap:anywhere}
pre{padding:18px;background:#edf6fc;border-left:4px solid #087096;border-radius:6px;white-space:pre-wrap;overflow-wrap:anywhere;font:16px/1.6 ui-monospace,SFMono-Regular,Consolas,monospace}pre code{padding:0;background:none;font:inherit}
table{width:100%;border-collapse:collapse;font:15px/1.45 system-ui,sans-serif;table-layout:fixed}th,td{padding:10px 7px;border-bottom:1px solid #d8e1e7;text-align:left;overflow-wrap:anywhere}th{font-weight:650;background:#edf6fc}td:nth-child(n+2){font-variant-numeric:tabular-nums}
@media(max-width:600px){body{font-size:19px}article{margin-top:28px;padding:0 20px}h1{font-size:34px;letter-spacing:-.7px}h2{font-size:26px}article img{max-width:none;width:calc(100% + 40px);margin-left:-20px}}
@media(max-width:600px){table{font-size:12px}th,td{padding:9px 4px}th:nth-child(1){width:27%}th:nth-child(2){width:17%}th:nth-child(3){width:24%}th:nth-child(4){width:32%}td:nth-child(n+2){white-space:nowrap}}
</style></head><body><div class="preview">Reading preview · Not published on Medium</div><article>'''+body+'''</article></body></html>'''
output = preview_directory / output_name
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(page)
print(f'PASS: {output} — {count} embedded PNGs; clickable email CTA; no remote image dependencies')
