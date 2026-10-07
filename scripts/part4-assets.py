#!/usr/bin/env python3
"""Stage Part 4's five inline images and separate poster; never install.
Run: python3 scripts/part4-assets.py OUTPUT_DIR
The practical-use line is native text, not an image.
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
    parser.error('Use a separate staging directory')
marker = '\ndo {\n    let args = CommandLine.arguments'

def helpers(name):
    source = (root / 'scripts' / name).read_text()
    if source.count(marker) != 1:
        raise ValueError(f'Cannot locate helper boundary: {name}')
    return source.split(marker, 1)[0]

with tempfile.TemporaryDirectory(prefix='part4-render-') as temporary:
    script = Path(temporary) / 'render.swift'
    script.write_text(helpers('circular-heroes.swift') + '\n' + helpers('part3-diagrams.swift') + '\n' + (root / 'scripts/part4-diagrams.swift').read_text())
    subprocess.run(['swift', str(script), str(output)], cwd=root, check=True)
