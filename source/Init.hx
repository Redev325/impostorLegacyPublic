package;

import funkin.FunkinAssets;

import flixel.FlxState;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

/**
 * Initiation state that prepares backend classes and returns to menus when finished.
 */
@:nullSafety(Strict)
class Init extends FlxState
{
		override public function create():Void
	{
		#if html5
		showHtml5TitleLoading();
		openfl.Assets.loadLibrary("title")
			.onProgress(function(loaded:Int, total:Int)
			{
				if (total > 0) updateHtml5TitleLoading(loaded / total);
			})
			.onComplete(function(_)
			{
				updateHtml5TitleLoading(1);
				removeHtml5TitleLoading();
				initializeGame();
			})
			.onError(function(error)
			{
				updateHtml5TitleLoadingError('Failed to load title assets: ' + Std.string(error));
			});
		#else
		initializeGame();
		#end
	}

	#if html5
	var html5LoadingOverlay:Null<openfl.display.Sprite> = null;
	var html5LoadingBar:Null<openfl.display.Shape> = null;
	var html5LoadingText:Null<openfl.text.TextField> = null;

	@:nullSafety(Off)
	function showHtml5TitleLoading():Void
	{
		final stage = openfl.Lib.current.stage;
		final width:Float = stage.stageWidth;
		final height:Float = stage.stageHeight;
		final barWidth:Float = Math.min(760, Math.max(280, width - 80));
		final barHeight:Float = 7;
		final barX:Float = (width - barWidth) * 0.5;
		final barY:Float = height - 28;

		html5LoadingOverlay = new openfl.display.Sprite();
		html5LoadingOverlay.graphics.beginFill(0x00345E, 1);
		html5LoadingOverlay.graphics.drawRect(0, 0, width, height);
		html5LoadingOverlay.graphics.endFill();

		final track = new openfl.display.Shape();
		track.graphics.beginFill(0x173F68, 1);
		track.graphics.drawRect(4, 0, barWidth - 8, barHeight);
		track.graphics.endFill();
		track.x = barX;
		track.y = barY;
		html5LoadingOverlay.addChild(track);

		html5LoadingBar = new openfl.display.Shape();
		html5LoadingBar.graphics.beginFill(0x5F6AFF, 1);
		html5LoadingBar.graphics.drawRect(0, 0, 1, barHeight);
		html5LoadingBar.graphics.endFill();
		html5LoadingBar.x = barX + 4;
		html5LoadingBar.y = barY;
		html5LoadingOverlay.addChild(html5LoadingBar);

		html5LoadingText = new openfl.text.TextField();
		html5LoadingText.defaultTextFormat = new openfl.text.TextFormat("_sans", 12, 0x5F6AFF);
		html5LoadingText.width = 300;
		html5LoadingText.height = 24;
		html5LoadingText.x = 2;
		html5LoadingText.y = barY - 13;
		html5LoadingText.text = "VS IMPOSTOR LEGACY 0%";
		html5LoadingText.selectable = false;
		html5LoadingText.mouseEnabled = false;
		html5LoadingOverlay.addChild(html5LoadingText);

		stage.addChild(html5LoadingOverlay);
	}

	@:nullSafety(Off)
	function updateHtml5TitleLoading(progress:Float):Void
	{
		if (html5LoadingBar == null || html5LoadingText == null) return;
		final stageWidth:Float = openfl.Lib.current.stage.stageWidth;
		final barWidth:Float = Math.min(760, Math.max(280, stageWidth - 80));
		final clamped:Float = Math.max(0, Math.min(1, progress));
		html5LoadingBar.scaleX = Math.max(0.001, ((barWidth - 8) * clamped));
		html5LoadingText.text = 'VS IMPOSTOR LEGACY ' + Std.int(clamped * 100) + '%';
	}

	@:nullSafety(Off)
	function updateHtml5TitleLoadingError(message:String):Void
	{
		if (html5LoadingText != null) html5LoadingText.text = message;
	}

	@:nullSafety(Off)
	function removeHtml5TitleLoading():Void
	{
		if (html5LoadingOverlay != null && html5LoadingOverlay.parent != null)
			html5LoadingOverlay.parent.removeChild(html5LoadingOverlay);
		html5LoadingOverlay = null;
		html5LoadingBar = null;
		html5LoadingText = null;
	}
	#end

	function initializeGame():Void
	{
		// load settings/save
		funkin.input.Controls.init();

		ClientPrefs.load();

		funkin.data.Highscore.load();

		if (FlxG.save.data.weekCompleted != null)
			funkin.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxSprite.defaultAntialiasing = ClientPrefs.globalAntialiasing;

		// Discord RPC disabled for HTML5

		#if MODS_ALLOWED
		funkin.Mods.pushGlobalMods();
		funkin.Mods.loadTopMod();
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = ClientPrefs.muteKeys;
		FlxG.sound.volumeDownKeys = ClientPrefs.volumeDownKeys;
		FlxG.sound.volumeUpKeys = ClientPrefs.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.mouse.visible = false;
		FlxG.plugins.drawOnTop = true;

		FlxG.scaleMode = new funkin.backend.FunkinRatioScaleMode();
		FlxG.signals.preStateSwitch.add((cast FlxG.scaleMode : funkin.backend.FunkinRatioScaleMode).resetSize);

		FlxG.sound.music = new extensions.flixel.FlxSoundEx();
		FlxG.sound.music.persist = true;

		funkin.data.Lang.reloadLangFile();

		funkin.backend.plugins.HotReloadPlugin.init();
		funkin.backend.plugins.DebugTextPlugin.init();
		funkin.backend.plugins.FullScreenPlugin.init();
		funkin.scripts.FunkinScript.init();

		#if VIDEOS_ALLOWED
		funkin.video.FunkinVideoSprite.init();
		#end

		#if FEATURE_DEBUG_TRACY
		funkin.utils.WindowUtil.initTracy();
		#end

		funkin.scripting.PluginsManager.prepareSignals();
		funkin.scripting.PluginsManager.populate();

		FunkinAssets.cache.currentTrackedSounds.addPermanentKey('assets/music/freakyMenu.ogg');

		super.create();

		final nextState:Class<FlxState> = Main.startMeta.skipSplash || !ClientPrefs.toggleSplashScreen ? Main.startMeta.initialState : Splash;
		FlxG.switchState(() -> Type.createInstance(nextState, []));
	}
}
