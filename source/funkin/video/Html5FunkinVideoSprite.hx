package funkin.video;

#if html5

import flixel.FlxSprite;
import flixel.util.FlxTimer;

import funkin.backend.Html5Video;

class Html5FunkinVideoSprite extends FlxSprite
{
	public static final looping:String = ':input-repeat=65535';
	public static final muted:String = ':no-audio';

	public var tiedToGame:Bool = true;
	public var time(get, set):Float;
	public var length(get, never):Float;
	public var playing(get, never):Bool;
	public var percent(get, never):Float;

	var sourcePath:String = '';
	var sourceOptions:Array<String> = [];
	var formatCallback:Null<Void->Void> = null;
	var startCallback:Null<Void->Void> = null;
	var endCallback:Null<Void->Void> = null;
	var endOnce:Bool = false;

	public function new(x:Float = 0, y:Float = 0, oneTimeUse:Bool = true)
	{
		super(x, y);
	}

	public function load(location:Dynamic, ?options:Array<String>):Bool
	{
		if (location == null) return false;
		sourcePath = Std.string(location);
		sourceOptions = options == null ? [] : options.copy();
		return sourcePath.length > 0;
	}

	public function delayAndStart(delay:Float = 0):Void
	{
		new FlxTimer().start(Math.max(0, delay), function(_) play());
	}

	public function onFormat(func:Void->Void, once:Bool = false, priority:Int = 0):Void
	{
		formatCallback = func;
	}

	public function onStart(func:Void->Void, once:Bool = false, priority:Int = 0):Void
	{
		startCallback = func;
	}

	public function onEnd(func:Void->Void, once:Bool = false, priority:Int = 0):Void
	{
		endCallback = func;
		endOnce = once;
	}

	public function play():Void
	{
		if (sourcePath.length == 0) return;

		final shouldMute:Bool = sourceOptions.contains(muted);
		final shouldLoop:Bool = sourceOptions.contains(looping);

		Html5Video.play(sourcePath,
			function() {
				if (formatCallback != null) formatCallback();
				if (startCallback != null) startCallback();
			},
			function() {
				final callback = endCallback;
				if (callback != null)
				{
					if (endOnce) endCallback = null;
					callback();
				}
			},
			function() {
				final callback = endCallback;
				if (callback != null)
				{
					if (endOnce) endCallback = null;
					callback();
				}
			},
			shouldMute,
			shouldLoop
		);
	}

	public function pause():Void
	{
		Html5Video.pause();
	}

	public function resume():Void
	{
		Html5Video.resume();
	}

	public function stop():Void
	{
		Html5Video.stop();
	}

	override function destroy():Void
	{
		if (playing) Html5Video.stop();
		super.destroy();
	}

	inline function get_time():Float return Html5Video.getTime();
	inline function set_time(value:Float):Float
	{
		final current = Html5Video.getTime();
		Html5Video.seek(value - current);
		return value;
	}

	inline function get_length():Float return Html5Video.getLength();
	inline function get_playing():Bool return Html5Video.isPlaying();
	inline function get_percent():Float return Html5Video.getPercent();
}
#end
