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

# Lime's HTML5 AssetHelper has changed its enum spelling between versions
# (FONT vs AssetType.FONT) and its indentation has changed. Match the actual
# structure rather than relying on one exact whitespace block.
pattern = re.compile(
    r'(?P<prefix>\t*\t*if \(asset\.type == (?:FONT|AssetType\.FONT)\)\s*\{'
    r'\s*assetData\.className = "__ASSET__" \+ asset\.flatName;\s*)'
    r'assetData\.preload = true;'
    r'(?P<suffix>\s*\}\s*else)',
    re.MULTILINE,
)

match = pattern.search(source)

if match:
    replacement = (
        match.group("prefix")
        + 'if (asset.library != null && libraries.exists(asset.library))\n'
        + '\t\t\t\t{\n'
        + '\t\t\t\t\tassetData.preload = libraries[asset.library].preload;\n'
        + '\t\t\t\t}\n'
        + '\t\t\t\telse if (libraries.exists(DEFAULT_LIBRARY_NAME))\n'
        + '\t\t\t\t{\n'
        + '\t\t\t\t\tassetData.preload = libraries[DEFAULT_LIBRARY_NAME].preload;\n'
        + '\t\t\t\t}'
        + match.group("suffix")
    )
    path.write_text(source[:match.start()] + replacement + source[match.end():])
    print(f"Patched Lime HTML5 font preload behavior in {path}")
else:
    # Make repeated workflow runs harmless.
    if "assetData.preload = libraries[asset.library].preload;" in source:
        print(f"Lime font preload patch already present: {path}")
    else:
        start = source.find("else if (project.target == HTML5)")
        if start >= 0:
            preview = source[start:start + 900]
            print("Lime HTML5 AssetHelper preview:")
            print(preview)
        raise SystemExit("Could not find Lime HTML5 font preload block")
