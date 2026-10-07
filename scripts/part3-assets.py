#!/usr/bin/env python3
"""Stage Part 3 PNGs, reusing the canonical hero/PNG/text helpers.
Run from any directory: python3 scripts/part3-assets.py OUTPUT_DIR
No content files are installed by this command.
"""
from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('output', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
output = args.output.resolve()
if output == root or output.is_relative_to(root / 'content'):
    parser.error('Use a separate staging directory, not the root or content tree')
source = (root / 'scripts/circular-heroes.swift').read_text()
marker = '\ndo {\n    let args = CommandLine.arguments'
if source.count(marker) != 1:
    raise ValueError('Cannot locate canonical hero helpers')
with tempfile.TemporaryDirectory(prefix='part3-render-') as temporary:
    script = Path(temporary) / 'render.swift'
    script.write_text(source.split(marker, 1)[0] + '\n' + (root / 'scripts/part3-diagrams.swift').read_text())
    subprocess.run(['swift', str(script), str(output)], cwd=root, check=True)
