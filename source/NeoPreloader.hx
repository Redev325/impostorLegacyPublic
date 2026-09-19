package;

import flixel.system.FlxBasePreloader;

import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * Real HTML5 preloader.
 *
 * FlxBasePreloader supplies the browser's actual bytesLoaded / bytesTotal
 * progress, so this percentage is not simulated.
 */
class NeoPreloader extends FlxBasePreloader
{
	var track:Shape;
	var fill:Shape;
	var label:TextField;

	override function create():Void
	{
		final width:Float = stage.stageWidth;
		final height:Float = stage.stageHeight;
		final barWidth:Float = Math.min(760, Math.max(280, width - 80));
		final x:Float = (width - barWidth) * 0.5;
		final y:Float = height * 0.5;

		final background = new Shape();
		background.graphics.beginFill(0x000000, 1);
		background.graphics.drawRect(0, 0, width, height);
		background.graphics.endFill();
		addChild(background);

		track = new Shape();
		track.graphics.beginFill(0x202020, 1);
		track.graphics.drawRoundRect(0, 0, barWidth, 18, 9, 9);
		track.graphics.endFill();
		track.x = x;
		track.y = y;
		addChild(track);

		fill = new Shape();
		fill.graphics.beginFill(0xFF4D6D, 1);
		fill.graphics.drawRoundRect(0, 0, 1, 18, 9, 9);
		fill.graphics.endFill();
		fill.x = x;
		fill.y = y;
		addChild(fill);

		label = new TextField();
		label.defaultTextFormat = new TextFormat("_sans", 18, 0xFFFFFF, true);
		label.width = barWidth;
		label.height = 40;
		label.x = x;
		label.y = y - 45;
		label.selectable = false;
		label.mouseEnabled = false;
		label.text = "Downloading game... 0%";
		addChild(label);

		super.create();
	}

	override function update(percent:Float):Void
	{
		if (fill == null || label == null) return;

		final barWidth:Float = Math.min(760, Math.max(280, stage.stageWidth - 80));
		final clamped:Float = Math.max(0, Math.min(1, percent));

		fill.scaleX = Math.max(0.002, (barWidth * clamped) / fill.width);
		label.text = "Downloading game... " + Std.int(clamped * 100) + "%";
	}

	override function destroy():Void
	{
		if (track != null && track.parent != null) track.parent.removeChild(track);
		if (fill != null && fill.parent != null) fill.parent.removeChild(fill);
		if (label != null && label.parent != null) label.parent.removeChild(label);

		track = null;
		fill = null;
		label = null;

		super.destroy();
	}
}
