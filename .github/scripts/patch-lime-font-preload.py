#!/usr/bin/env python3
from pathlib import Path

OLD = """			if (asset.type == AssetType.FONT)
			{
				assetData.className = "__ASSET__" + asset.flatName;
				assetData.preload = true;
			}
			else"""

NEW = """			if (asset.type == AssetType.FONT)
			{
				assetData.className = "__ASSET__" + asset.flatName;
				if (asset.library != null && libraries.exists(asset.library))
				{
					assetData.preload = libraries[asset.library].preload;
				}
				else if (libraries.exists(DEFAULT_LIBRARY_NAME))
				{
					assetData.preload = libraries[DEFAULT_LIBRARY_NAME].preload;
				}
			}
			else"""

candidates = [
    p for p in Path(".haxelib/lime").rglob("AssetHelper.hx")
    if p.as_posix().endswith("/src/lime/tools/AssetHelper.hx")
]
if not candidates:
    raise SystemExit("Could not find Lime AssetHelper.hx")

path = candidates[0]
source = path.read_text()

if NEW in source:
    print(f"Lime font preload patch already present: {path}")
elif OLD in source:
    path.write_text(source.replace(OLD, NEW, 1))
    print(f"Patched Lime HTML5 font preload behavior in {path}")
else:
    raise SystemExit("Expected Lime HTML5 font preload block was not found")
