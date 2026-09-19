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
		showHtml5Loading();
		loadStartupAssets();
		#else
		initializeGame();
		#end
	}

	#if html5
	var loadingOverlay:Null<openfl.display.Sprite> = null;
	var loadingTrack:Null<openfl.display.Shape> = null;
	var loadingFill:Null<openfl.display.Shape> = null;
	var loadingText:Null<openfl.text.TextField> = null;

	var startupAssets:Array<{id:String, type:openfl.utils.AssetType}> = [];
	var startupNext:Int = 0;
	var startupActive:Int = 0;
	var startupCompleted:Int = 0;
	var startupFailed:Bool = false;

	static inline final STARTUP_CONCURRENCY:Int = 6;

	@:nullSafety(Off)
	function loadStartupAssets():Void
	{
		final library = openfl.Assets.getLibrary("startup");
		if (library == null)
		{
			updateHtml5LoadingError('Startup asset library was not registered.');
			return;
		}

		startupAssets = [];
		for (id in library.list())
		{
			final type:openfl.utils.AssetType =
				if (library.exists(id, openfl.utils.AssetType.IMAGE)) openfl.utils.AssetType.IMAGE;
				else if (library.exists(id, openfl.utils.AssetType.SOUND)) openfl.utils.AssetType.SOUND;
				else if (library.exists(id, openfl.utils.AssetType.FONT)) openfl.utils.AssetType.FONT;
				else if (library.exists(id, openfl.utils.AssetType.TEXT)) openfl.utils.AssetType.TEXT;
				else openfl.utils.AssetType.BINARY;

			startupAssets.push({id: id, type: type});
		}

		if (startupAssets.length == 0)
		{
			updateHtml5LoadingError('No startup assets were found.');
			return;
		}

		startupNext = 0;
		startupActive = 0;
		startupCompleted = 0;
		startupFailed = false;

		updateHtml5Loading(0);
		updateHtml5LoadingStatus('Loading startup assets... 0/' + startupAssets.length);
		pumpStartupLoads();
	}

	@:nullSafety(Off)
	function pumpStartupLoads():Void
	{
		if (startupFailed) return;

		while (startupActive < STARTUP_CONCURRENCY && startupNext < startupAssets.length)
		{
			final asset = startupAssets[startupNext++];
			startupActive++;
			updateHtml5LoadingStatus('Loading startup asset: ' + asset.id);

			openfl.Assets.loadAsset('startup:' + asset.id, asset.type)
				.onComplete(function(_)
				{
					startupActive--;
					startupCompleted++;

					final progress:Float = startupCompleted / startupAssets.length;
					updateHtml5Loading(progress);
					updateHtml5LoadingStatus('Loaded startup assets: ' + startupCompleted + '/' + startupAssets.length);

					if (startupCompleted >= startupAssets.length)
					{
						removeHtml5Loading();
						initializeGame();
					}
					else
					{
						pumpStartupLoads();
					}
				})
				.onError(function(error)
				{
					startupActive--;
					startupFailed = true;
					updateHtml5LoadingError('Failed startup asset: ' + asset.id + '\\n' + Std.string(error));
				});
		}
	}

	@:nullSafety(Off)
	function showHtml5Loading():Void
	{
		final stage = openfl.Lib.current.stage;
		final width:Float = stage.stageWidth;
		final height:Float = stage.stageHeight;
		final barWidth:Float = Math.min(760, Math.max(280, width - 80));
		final barX:Float = (width - barWidth) * 0.5;
		final barY:Float = height * 0.5;

		loadingOverlay = new openfl.display.Sprite();
		loadingOverlay.graphics.beginFill(0x000000, 1);
		loadingOverlay.graphics.drawRect(0, 0, width, height);
		loadingOverlay.graphics.endFill();

		loadingTrack = new openfl.display.Shape();
		loadingTrack.graphics.beginFill(0x2A2A2A, 1);
		loadingTrack.graphics.drawRoundRect(0, 0, barWidth, 18, 9, 9);
		loadingTrack.graphics.endFill();
		loadingTrack.x = barX;
		loadingTrack.y = barY;
		loadingOverlay.addChild(loadingTrack);

		loadingFill = new openfl.display.Shape();
		loadingFill.graphics.beginFill(0xFF4D6D, 1);
		loadingFill.graphics.drawRoundRect(0, 0, 1, 18, 9, 9);
		loadingFill.graphics.endFill();
		loadingFill.x = barX;
		loadingFill.y = barY;
		loadingOverlay.addChild(loadingFill);

		loadingText = new openfl.text.TextField();
		loadingText.defaultTextFormat = new openfl.text.TextFormat("_sans", 18, 0xFFFFFF, true);
		loadingText.width = barWidth;
		loadingText.height = 60;
		loadingText.x = barX;
		loadingText.y = barY - 45;
		loadingText.text = "Loading VS IMPOSTOR: LEGACY... 0%";
		loadingText.selectable = false;
		loadingText.mouseEnabled = false;
		loadingOverlay.addChild(loadingText);

		stage.addChild(loadingOverlay);
	}

	@:nullSafety(Off)
	function updateHtml5LoadingStatus(status:String):Void
	{
		if (loadingText != null) loadingText.text = status;
	}

	@:nullSafety(Off)
	function updateHtml5Loading(progress:Float):Void
	{
		if (loadingFill == null || loadingText == null) return;

		final stageWidth:Float = openfl.Lib.current.stage.stageWidth;
		final barWidth:Float = Math.min(760, Math.max(280, stageWidth - 80));
		final clamped:Float = Math.max(0, Math.min(1, progress));

		loadingFill.scaleX = Math.max(0.01, (barWidth * clamped) / loadingFill.width);
		loadingText.text = 'Loading VS IMPOSTOR: LEGACY... ' + Std.int(clamped * 100) + '%';
	}

	@:nullSafety(Off)
	function updateHtml5LoadingError(message:String):Void
	{
		if (loadingText != null)
			loadingText.text = message + '\nRefresh the page to try again.';
	}

	@:nullSafety(Off)
	function removeHtml5Loading():Void
	{
		if (loadingOverlay != null && loadingOverlay.parent != null)
			loadingOverlay.parent.removeChild(loadingOverlay);

		loadingTrack = null;
		loadingFill = null;
		loadingText = null;
		loadingOverlay = null;
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
