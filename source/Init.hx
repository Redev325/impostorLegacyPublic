package;

import funkin.FunkinAssets;

import flixel.FlxState;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

/**
 * Initiation state that prepares backend classes and returns to menus when finished
 * 
 * There is no need to open this beyond the first time
 */
@:nullSafety(Strict)
class Init extends FlxState
{
	override public function create():Void
	{
		#if html5
		showHtml5Loading();
		openfl.Assets.loadLibrary("default")
			.onProgress(function(loaded:Int, total:Int)
			{
				if (total > 0) updateHtml5Loading(loaded / total);
			})
			.onComplete(function(_)
			{
				removeHtml5Loading();
				initializeGame();
			})
			.onError(function(error)
			{
				updateHtml5LoadingError('Failed to load game assets. ' + Std.string(error));
			});
		#else
			initializeGame();
		#end
	}

	#if html5
	var loadingOverlay:Null<openfl.display.Sprite> = null;
	var loadingFill:Null<openfl.display.Shape> = null;
	var loadingText:Null<openfl.text.TextField> = null;

	@:nullSafety(Off)
	function showHtml5Loading():Void
	{
		loadingOverlay = new openfl.display.Sprite();
		loadingOverlay.graphics.beginFill(0x000000, 1);
		loadingOverlay.graphics.drawRect(0, 0, openfl.Lib.current.stage.stageWidth, openfl.Lib.current.stage.stageHeight);
		loadingOverlay.graphics.endFill();

		final stageWidth:Float = openfl.Lib.current.stage.stageWidth;
		final stageHeight:Float = openfl.Lib.current.stage.stageHeight;
		final barWidth:Float = Math.min(760, Math.max(280, stageWidth - 80));
		final barX:Float = (stageWidth - barWidth) * 0.5;
		final barY:Float = stageHeight * 0.5;

		loadingOverlay.graphics.beginFill(0x202020, 1);
		loadingOverlay.graphics.drawRoundRect(barX, barY, barWidth, 18, 9, 9);
		loadingOverlay.graphics.endFill();

		loadingFill = new openfl.display.Shape();
		loadingFill.graphics.beginFill(0xFF4D6D, 1);
		loadingFill.graphics.drawRoundRect(0, 0, 2, 18, 9, 9);
		loadingFill.graphics.endFill();
		loadingFill.x = barX;
		loadingFill.y = barY;
		loadingOverlay.addChild(loadingFill);

		loadingText = new openfl.text.TextField();
		loadingText.defaultTextFormat = new openfl.text.TextFormat("_sans", 18, 0xFFFFFF, true);
		loadingText.width = barWidth;
		loadingText.height = 70;
		loadingText.x = barX;
		loadingText.y = barY - 48;
		loadingText.text = "Loading VS IMPOSTOR: LEGACY...";
		loadingText.selectable = false;
		loadingText.mouseEnabled = false;
		loadingOverlay.addChild(loadingText);

		openfl.Lib.current.stage.addChild(loadingOverlay);
	}

	@:nullSafety(Off)
	function updateHtml5Loading(progress:Float):Void
	{
		if (loadingOverlay == null || loadingFill == null || loadingText == null) return;

		final stageWidth:Float = openfl.Lib.current.stage.stageWidth;
		final barWidth:Float = Math.min(760, Math.max(280, stageWidth - 80));
		final barX:Float = (stageWidth - barWidth) * 0.5;
		final clamped:Float = Math.max(0, Math.min(1, progress));

		loadingFill.scaleX = Math.max(0.01, (barWidth * clamped) / loadingFill.width);
		loadingText.text = 'Loading VS IMPOSTOR: LEGACY... ' + Std.int(clamped * 100) + '%';
	}

	@:nullSafety(Off)
	function updateHtml5LoadingError(message:String):Void
	{
		if (loadingText == null) return;
		loadingText.text = message + '\nRefresh the page to try again.';
	}

	@:nullSafety(Off)
	function removeHtml5Loading():Void
	{
		if (loadingOverlay != null && loadingOverlay.parent != null) loadingOverlay.parent.removeChild(loadingOverlay);
		loadingOverlay = null;
		loadingFill = null;
		loadingText = null;
	}
	#end

	function initializeGame():Void
	{
		// load settings/save
		funkin.input.Controls.init();
		
		ClientPrefs.load();
		
		funkin.data.Highscore.load();
		
		if (FlxG.save.data.weekCompleted != null) funkin.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		
		FlxSprite.defaultAntialiasing = ClientPrefs.globalAntialiasing;
		
		// Discord RPC disabled for HTML5
		
		#if MODS_ALLOWED
		funkin.Mods.pushGlobalMods();
		funkin.Mods.loadTopMod();
		#end
		
		// set some flixel settings
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
		
		// ready backends
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
