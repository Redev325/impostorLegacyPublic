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

# Lime has two HTML5 font-generation paths:
# - getAssetData() for ordinary/unpacked libraries
# - getPackedAssetData() for packed libraries
# Both historically forced HTML5 fonts to preload=true.
ordinary_pattern = re.compile(
    r'(?P<indent>\t+)if \(asset\.type == (?:FONT|AssetType\.FONT)\)\s*\{'
    r'\s*assetData\.className = "__ASSET__" \+ asset\.flatName;\s*'
    r'assetData\.preload = true;'
    r'(?P<tail>\s*\}\s*else)',
    re.MULTILINE,
)

ordinary_replacement = (
    '\\g<indent>if (asset.type == FONT)\n'
    '\\g<indent>{\n'
    '\\g<indent}\tassetData.className = "__ASSET__" + asset.flatName;\n'
    '\\g<indent}\tif (libraries.exists(library))\n'
    '\\g<indent}\t{\n'
    '\\g<indent}\t\tassetData.preload = libraries[library].preload;\n'
    '\\g<indent}\t}\n'
    '\\g<indent>}\\g<tail>'
)

match = ordinary_pattern.search(source)
if match:
    source = source[:match.start()] + ordinary_replacement.replace(
        '\\g<indent>', match.group('indent')
    ).replace('\\g<tail>', match.group('tail')) + source[match.end():]
    print("Patched ordinary HTML5 font preload path.")
elif "assetData.preload = libraries[library].preload;" in source:
    print("Ordinary HTML5 font preload path already patched.")
else:
    raise SystemExit("Could not find ordinary HTML5 font preload block")

packed_pattern = re.compile(
    r'(?P<indent>\t+)if \(project\.target == HTML5 && asset\.type == (?:FONT|AssetType\.FONT)\)\s*\{'
    r'\s*assetData\.className = "__ASSET__" \+ asset\.flatName;\s*'
    r'assetData\.preload = true;\s*\}',
    re.MULTILINE,
)

packed_replacement_template = (
    "{indent}if (project.target == HTML5 && asset.type == FONT)\n"
    "{indent}{{\n"
    "{indent}\tassetData.className = \"__ASSET__\" + asset.flatName;\n"
    "{indent}\tassetData.preload = library.preload;\n"
    "{indent}}}"
)

match = packed_pattern.search(source)
if match:
    replacement = packed_replacement_template.format(indent=match.group('indent'))
    source = source[:match.start()] + replacement + source[match.end():]
    print("Patched packed HTML5 font preload path.")
elif "assetData.preload = library.preload;" in source:
    print("Packed HTML5 font preload path already patched.")
else:
    raise SystemExit("Could not find packed HTML5 font preload block")

# Verify the actual two font blocks, rather than using a broad DOTALL search
# that can accidentally span unrelated code later in the file.
html5_start = source.find("else if (project.target == HTML5)")
if html5_start < 0:
    raise SystemExit("Could not locate Lime HTML5 branch after patching")

html5_end = source.find("\n\t\telse\n", html5_start)
if html5_end < 0:
    html5_end = len(source)
html5_branch = source[html5_start:html5_end]

font_block = re.search(
    r'if \(asset\.type == FONT\)\s*\{.*?\}',
    html5_branch,
    re.DOTALL,
)
if not font_block or "assetData.preload = true;" in font_block.group(0):
    raise SystemExit("Ordinary HTML5 font block still forces preload=true")

packed_start = source.find("if (project.target == HTML5 && asset.type == FONT)")
if packed_start < 0:
    raise SystemExit("Could not locate packed HTML5 font block after patching")
packed_end = source.find("\n\t\t\telse", packed_start)
packed_block = source[packed_start:packed_end if packed_end >= 0 else len(source)]
if "assetData.preload = true;" in packed_block:
    raise SystemExit("Packed HTML5 font block still forces preload=true")

print(f"Verified both Lime HTML5 font preload paths: {path}")
path.write_text(source)
