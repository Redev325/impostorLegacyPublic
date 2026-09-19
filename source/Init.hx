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
		loadHtml5StartupAssets();
		#else
		initializeGame();
		#end
	}

	#if html5
	function loadHtml5StartupAssets():Void
	{
		// Register the library first. Every asset is preloaded explicitly below so
		// the progress bar represents the actual assets being downloaded/decoded.
		openfl.Assets.loadLibrary("startup").onComplete(function(_)
		{
			final assets:Array<{id:String, type:openfl.utils.AssetType}> = [
				{id: "startup:assets/data/introText.txt", type: openfl.utils.AssetType.TEXT},
				{id: "startup:assets/lang/english.json", type: openfl.utils.AssetType.TEXT},
				{id: "startup:assets/fonts/vcr.ttf", type: openfl.utils.AssetType.FONT},
				{id: "startup:assets/fonts/vcr-srb.ttf", type: openfl.utils.AssetType.FONT},
				{id: "startup:assets/images/logoBumpin.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/images/logoBumpin.xml", type: openfl.utils.AssetType.TEXT},
				{id: "startup:assets/images/alphabet.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/images/alphabet.xml", type: openfl.utils.AssetType.TEXT},
				{id: "startup:assets/images/cursor.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/images/menu/common/starBG.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/images/menu/common/starFG.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/images/menu/common/menuBack.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/images/menu/common/menuOther.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/images/menu/title/startText.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/images/menu/title/startText.xml", type: openfl.utils.AssetType.TEXT},
				{id: "startup:assets/images/menu/title/funkin.png", type: openfl.utils.AssetType.IMAGE},
				{id: "startup:assets/sounds/confirmMenu.ogg", type: openfl.utils.AssetType.SOUND},
				{id: "startup:assets/sounds/cancelMenu.ogg", type: openfl.utils.AssetType.SOUND},
				{id: "startup:assets/sounds/scrollMenu.ogg", type: openfl.utils.AssetType.SOUND},
				{id: "startup:assets/music/freakyMenu.ogg", type: openfl.utils.AssetType.MUSIC}
			];

			loadHtml5AssetList(assets, 0);
		}).onError(function(error)
		{
			updateHtml5LoadingError('Failed to register startup assets. ' + Std.string(error));
		});
	}

	function loadHtml5AssetList(assets:Array<{id:String, type:openfl.utils.AssetType}>, index:Int):Void
	{
		if (index >= assets.length)
		{
			updateHtml5Loading(1);
			removeHtml5Loading();
			initializeGame();
			return;
		}

		final item = assets[index];
		updateHtml5Loading(index / assets.length);
		var future:Dynamic = switch (item.type)
		{
			case openfl.utils.AssetType.IMAGE: openfl.Assets.loadBitmapData(item.id, true);
			case openfl.utils.AssetType.FONT: openfl.Assets.loadFont(item.id, true);
			case openfl.utils.AssetType.SOUND, openfl.utils.AssetType.MUSIC: openfl.Assets.loadSound(item.id, true);
			case openfl.utils.AssetType.TEXT: openfl.Assets.loadText(item.id);
			default: openfl.Assets.loadBytes(item.id);
		};
		future
			.onProgress(function(loaded:Int, total:Int)
			{
				if (total > 0)
				{
					final assetProgress = Math.max(0, Math.min(1, loaded / total));
					updateHtml5Loading((index + assetProgress) / assets.length);
				}
			})
			.onComplete(function(_)
			{
				updateHtml5Loading((index + 1) / assets.length);
				loadHtml5AssetList(assets, index + 1);
			})
			.onError(function(error)
			{
				updateHtml5LoadingError('Failed to load ' + item.id + ': ' + Std.string(error));
			});
	}

	var loadingOverlay:Null<openfl.display.Sprite> = null;
	var loadingTrack:Null<openfl.display.Shape> = null;
	var loadingFill:Null<openfl.display.Shape> = null;
	var loadingText:Null<openfl.text.TextField> = null;

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
		if (loadingText != null) loadingText.text = message + '\\nRefresh the page to try again.';
	}

	@:nullSafety(Off)
	function removeHtml5Loading():Void
	{
		if (loadingOverlay != null && loadingOverlay.parent != null) loadingOverlay.parent.removeChild(loadingOverlay);
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
		
		if (FlxG.save.data.weekCompleted != null) funkin.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		
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
