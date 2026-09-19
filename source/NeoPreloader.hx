package;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.system.FlxBasePreloader;

/**
 * Real HTML5 preloader.
 *
 * FlxBasePreloader receives progress from Lime/OpenFL's preloaded asset
 * libraries, so the percentage shown here tracks actual bytes loaded rather
 * than simulated time or a scripted percentage.
 */
class NeoPreloader extends FlxBasePreloader
{
	var overlay:Sprite;
	var track:Shape;
	var fill:Shape;
	var label:TextField;

	override function create():Void
	{
		final width = Lib.current.stage.stageWidth;
		final height = Lib.current.stage.stageHeight;
		final barWidth:Float = Math.min(760, Math.max(280, width - 80));
		final barX:Float = (width - barWidth) * 0.5;
		final barY:Float = height * 0.5;

		overlay = new Sprite();
		overlay.graphics.beginFill(0x000000, 1);
		overlay.graphics.drawRect(0, 0, width, height);
		overlay.graphics.endFill();
		addChild(overlay);

		track = new Shape();
		track.graphics.beginFill(0x202020, 1);
		track.graphics.drawRoundRect(0, 0, barWidth, 18, 9, 9);
		track.graphics.endFill();
		track.x = barX;
		track.y = barY;
		overlay.addChild(track);

		fill = new Shape();
		fill.graphics.beginFill(0xFF4D6D, 1);
		fill.graphics.drawRoundRect(0, 0, barWidth, 18, 9, 9);
		fill.graphics.endFill();
		fill.x = barX - barWidth;
		fill.y = barY;
		overlay.addChild(fill);

		label = new TextField();
		label.defaultTextFormat = new TextFormat("_sans", 18, 0xFFFFFF, true);
		label.width = barWidth;
		label.height = 60;
		label.x = barX;
		label.y = barY - 45;
		label.selectable = false;
		label.mouseEnabled = false;
		label.text = "Loading VS IMPOSTOR: LEGACY... 0%";
		overlay.addChild(label);

		super.create();
	}

	override function update(percent:Float):Void
	{
		final clamped = Math.max(0, Math.min(1, percent));
		final barWidth:Float = track.width;
		fill.scaleX = Math.max(0.0001, clamped);
		fill.x = track.x - barWidth + barWidth * (1 - clamped);
		label.text = "Loading VS IMPOSTOR: LEGACY... " + Std.int(clamped * 100) + "%";
	}

	override function destroy():Void
	{
		if (overlay != null && overlay.parent != null)
			overlay.parent.removeChild(overlay);

		overlay = null;
		track = null;
		fill = null;
		label = null;

		super.destroy();
	}
}
