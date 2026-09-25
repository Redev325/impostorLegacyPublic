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

# Lime has TWO HTML5 font paths:
# 1) getAssetData() for ordinary/unpacked libraries
# 2) getPackedAssetData() for packed libraries
# Both used to force fonts to preload=true. Patch both paths.
ordinary_pattern = re.compile(
    r'(?P<indent>\t*)if \(asset\.type == (?:FONT|AssetType\.FONT)\)\s*\{'
    r'\s*assetData\.className = "__ASSET__" \+ asset\.flatName;\s*'
    r'(?P<preload>assetData\.preload = true;)'
    r'\s*\}\s*else',
    re.MULTILINE,
)

# In getAssetData(), the parameter named library is the resolved library name.
ordinary_replacement = (
    '\\g<indent>if (asset.type == FONT)\n'
    '\\g<indent>{\n'
    '\\g<indent>\tassetData.className = "__ASSET__" + asset.flatName;\n'
    '\\g<indent>\tif (libraries.exists(library))\n'
    '\\g<indent>\t{\n'
    '\\g<indent>\t\tassetData.preload = libraries[library].preload;\n'
    '\\g<indent>\t}\n'
    '\\g<indent>}\n'
    '\\g<indent>else'
)

# Patch ONLY the first matching HTML5 font block (getAssetData).
match = ordinary_pattern.search(source)
if match and "libraries.exists(library)" not in match.group(0):
    source = source[:match.start()] + ordinary_pattern.sub(ordinary_replacement, match.group(0), count=1) + source[match.end():]
    print("Patched ordinary HTML5 font preload path.")

# Packed-library font path uses the Library object directly.
packed_pattern = re.compile(
    r'(?P<indent>\t*)if \(project\.target == HTML5 && asset\.type == (?:FONT|AssetType\.FONT)\)\s*\{'
    r'\s*assetData\.className = "__ASSET__" \+ asset\.flatName;\s*'
    r'(?P<preload>assetData\.preload = true;)\s*\}',
    re.MULTILINE,
)
packed_replacement = (
    '\\g<indent>if (project.target == HTML5 && asset.type == FONT)\n'
    '\\g<indent>{\n'
    '\\g<indent>\tassetData.className = "__ASSET__" + asset.flatName;\n'
    '\\g<indent>\tassetData.preload = library.preload;\n'
    '\\g<indent>}'
)

match = packed_pattern.search(source)
if match and "assetData.preload = library.preload;" not in match.group(0):
    source = source[:match.start()] + packed_pattern.sub(packed_replacement, match.group(0), count=1) + source[match.end():]
    print("Patched packed HTML5 font preload path.")

# Verify the forced-preload implementations are gone from both branches.
forced_blocks = re.findall(
    r'if \((?:project\.target == HTML5 && )?asset\.type == (?:FONT|AssetType\.FONT)\).*?assetData\.preload = true;',
    source,
    flags=re.DOTALL,
)
if forced_blocks:
    raise SystemExit("A forced HTML5 font preload block remains in Lime AssetHelper.hx")

if (
    "libraries.exists(library)" not in source
    and "assetData.preload = library.preload;" not in source
):
    raise SystemExit("Lime font preload patch was not applied")

path.write_text(source)
print(f"Using Lime AssetHelper.hx: {path}")
