#!/usr/bin/env python3
from pathlib import Path

candidates = [
    p for p in Path(".haxelib/lime").rglob("AssetHelper.hx")
    if p.as_posix().endswith("/src/lime/tools/AssetHelper.hx")
]
if not candidates:
    raise SystemExit("Could not find Lime AssetHelper.hx")

path = candidates[0]
source = path.read_text()

# This repository pins FunkinCrew/lime at a known commit. At that commit,
# AssetHelper has two HTML5 font paths and both force preload=true.
old_ordinary = """\t\tif (project.target == HTML5)
\t\t{
\t\t\tif (asset.type == FONT)
\t\t\t{
\t\t\t\tassetData.className = "__ASSET__" + asset.flatName;
\t\t\t\tassetData.preload = true;
\t\t\t}
\t\t\telse"""
new_ordinary = """\t\tif (project.target == HTML5)
\t\t{
\t\t\tif (asset.type == FONT)
\t\t\t{
\t\t\t\tassetData.className = "__ASSET__" + asset.flatName;
\t\t\t\tif (libraries.exists(library))
\t\t\t\t{
\t\t\t\t\tassetData.preload = libraries[library].preload;
\t\t\t\t}
\t\t\t}
\t\t\telse"""

old_packed = """\t\t\tif (project.target == HTML5 && asset.type == FONT)
\t\t\t{
\t\t\t\tassetData.className = "__ASSET__" + asset.flatName;
\t\t\t\tassetData.preload = true;
\t\t\t}"""
new_packed = """\t\t\tif (project.target == HTML5 && asset.type == FONT)
\t\t\t{
\t\t\t\tassetData.className = "__ASSET__" + asset.flatName;
\t\t\t\tassetData.preload = library.preload;
\t\t\t}"""

changed = False

if old_ordinary in source:
    source = source.replace(old_ordinary, new_ordinary, 1)
    print("Patched ordinary HTML5 font preload path.")
    changed = True
elif new_ordinary in source:
    print("Ordinary HTML5 font preload path already patched.")
else:
    raise SystemExit("Could not find the pinned Lime ordinary HTML5 font block")

if old_packed in source:
    source = source.replace(old_packed, new_packed, 1)
    print("Patched packed HTML5 font preload path.")
    changed = True
elif new_packed in source:
    print("Packed HTML5 font preload path already patched.")
else:
    raise SystemExit("Could not find the pinned Lime packed HTML5 font block")

path.write_text(source)
print(f"Verified Lime HTML5 font preload patch in {path}")
