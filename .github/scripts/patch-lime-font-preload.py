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

# Patch the FONT branch inside the actual HTML5 getAssetData() section.
# There is another FONT branch earlier in AssetHelper.hx for Flash/AIR, so
# matching the first generic "if (asset.type == FONT)" is incorrect.
html5_start = source.find("else if (project.target == HTML5)")
if html5_start < 0:
    raise SystemExit("Could not find HTML5 branch in Lime AssetHelper.hx")

html5_end = source.find("\n\t\telse\n", html5_start)
if html5_end < 0:
    html5_end = len(source)

html5 = source[html5_start:html5_end]

old_font = """\t\t\tif (asset.type == FONT)
\t\t\t{
\t\t\t\tassetData.className = "__ASSET__" + asset.flatName;
\t\t\t\tassetData.preload = true;
\t\t\t}
\t\t\telse"""
new_font = """\t\t\tif (asset.type == FONT)
\t\t\t{
\t\t\t\tassetData.className = "__ASSET__" + asset.flatName;
\t\t\t\tif (libraries.exists(library))
\t\t\t\t{
\t\t\t\t\tassetData.preload = libraries[library].preload;
\t\t\t\t}
\t\t\t}
\t\t\telse"""

if old_font in html5:
    html5 = html5.replace(old_font, new_font, 1)
    print("Patched ordinary HTML5 font preload path.")
elif "assetData.preload = libraries[library].preload;" in html5:
    print("Ordinary HTML5 font preload path already patched.")
else:
    raise SystemExit("Could not find ordinary HTML5 font block inside the HTML5 branch")

source = source[:html5_start] + html5 + source[html5_end:]

# Patch the packed-library HTML5 font branch.
packed_old = """\t\t\tif (project.target == HTML5 && asset.type == FONT)
\t\t\t{
\t\t\t\tassetData.className = "__ASSET__" + asset.flatName;
\t\t\t\tassetData.preload = true;
\t\t\t}"""
packed_new = """\t\t\tif (project.target == HTML5 && asset.type == FONT)
\t\t\t{
\t\t\t\tassetData.className = "__ASSET__" + asset.flatName;
\t\t\t\tassetData.preload = library.preload;
\t\t\t}"""

if packed_old in source:
    source = source.replace(packed_old, packed_new, 1)
    print("Patched packed HTML5 font preload path.")
elif "assetData.preload = library.preload;" in source:
    print("Packed HTML5 font preload path already patched.")
else:
    raise SystemExit("Could not find packed HTML5 font block")

# Verify the exact HTML5 sections contain no forced font preload.
verify_start = source.find("else if (project.target == HTML5)")
verify_end = source.find("\n\t\telse\n", verify_start)
if verify_end < 0:
    verify_end = len(source)
verify_html5 = source[verify_start:verify_end]

font_forced = re.findall(
    r'if\s*\(asset\.type\s*==\s*FONT\)\s*\{.*?assetData\.preload\s*=\s*true;.*?\}',
    verify_html5,
    flags=re.DOTALL,
)
if font_forced:
    raise SystemExit("Ordinary HTML5 font branch still forces preload=true")

packed_index = source.find("if (project.target == HTML5 && asset.type == FONT)")
if packed_index >= 0:
    packed_close = source.find("\n\t\t\telse", packed_index)
    if packed_close < 0:
        packed_close = len(source)
    packed_section = source[packed_index:packed_close]
    if "assetData.preload = true;" in packed_section:
        raise SystemExit("Packed HTML5 font branch still forces preload=true")

path.write_text(source)
print(f"Verified Lime HTML5 font preload patch: {path}")
