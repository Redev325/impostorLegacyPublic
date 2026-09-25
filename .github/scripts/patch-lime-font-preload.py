#!/usr/bin/env python3
from pathlib import Path
import re

candidates = [
    p for p in Path(".haxelib/lime").rglob("AssetHelper.hx")
    if p.as_posix().endswith("/src/lime/tools/AssetHelper.hx")
]
if not candidates:
    raise SystemExit("Could not find Lime AssetHelper.hx")

path = candidates[0]
source = path.read_text()

# HTML5 fonts are handled by two different Lime functions. In both places
# upstream Lime forces preload=true, which makes deferred font libraries part
# of the blue HTML5 preloader. Replace only that forced assignment.
ordinary = re.compile(
    r'(?P<block>'
    r'(?P<indent>\s*)if\s*\(asset\.type\s*==\s*(?:FONT|AssetType\.FONT)\)\s*\{'
    r'.*?'
    r'(?P<preload_indent>\s*)assetData\.preload\s*=\s*true;'
    r'.*?\})',
    re.DOTALL,
)

packed = re.compile(
    r'(?P<block>'
    r'(?P<indent>\s*)if\s*\(project\.target\s*==\s*HTML5\s*&&\s*asset\.type\s*==\s*(?:FONT|AssetType\.FONT)\)\s*\{'
    r'.*?'
    r'(?P<preload_indent>\s*)assetData\.preload\s*=\s*true;'
    r'.*?\})',
    re.DOTALL,
)

def patch_ordinary(match):
    block = match.group("block")
    indent = match.group("indent").split("\n")[-1]
    body_indent = match.group("preload_indent").split("\n")[-1]
    replacement = f"{body_indent}if (libraries.exists(library))\\n{body_indent}{{\\n{body_indent}\\tassetData.preload = libraries[library].preload;\\n{body_indent}}}"
    return block.replace(
        f"{match.group('preload_indent')}assetData.preload = true;",
        replacement,
        1,
    )

def patch_packed(match):
    block = match.group("block")
    body_indent = match.group("preload_indent").split("\n")[-1]
    replacement = f"{body_indent}assetData.preload = library.preload;"
    return block.replace(
        f"{match.group('preload_indent')}assetData.preload = true;",
        replacement,
        1,
    )

ordinary_matches = list(ordinary.finditer(source))
ordinary_changed = 0
for match in reversed(ordinary_matches):
    block = match.group("block")
    if "assetData.preload = true;" in block:
        start, end = match.span("block")
        source = source[:start] + patch_ordinary(match) + source[end:]
        ordinary_changed += 1

packed_matches = list(packed.finditer(source))
packed_changed = 0
for match in reversed(packed_matches):
    block = match.group("block")
    if "assetData.preload = true;" in block:
        start, end = match.span("block")
        source = source[:start] + patch_packed(match) + source[end:]
        packed_changed += 1

path.write_text(source)

print(f"Lime AssetHelper: {path}")
print(f"Ordinary HTML5 font blocks patched: {ordinary_changed}")
print(f"Packed HTML5 font blocks patched: {packed_changed}")

# Verify only the font blocks themselves. Do not inspect the whole file or
# require a particular surrounding branch spelling.
remaining = []
for match in re.finditer(
    r'if\s*\(asset\.type\s*==\s*(?:FONT|AssetType\.FONT)\)\s*\{.*?\}',
    source,
    re.DOTALL,
):
    if "assetData.preload = true;" in match.group(0):
        remaining.append("ordinary")

for match in re.finditer(
    r'if\s*\(project\.target\s*==\s*HTML5\s*&&\s*asset\.type\s*==\s*(?:FONT|AssetType\.FONT)\)\s*\{.*?\}',
    source,
    re.DOTALL,
):
    if "assetData.preload = true;" in match.group(0):
        remaining.append("packed")

if remaining:
    raise SystemExit("Forced HTML5 font preload remains in: " + ", ".join(remaining))

print("Verified: no HTML5 font block still forces preload=true.")
