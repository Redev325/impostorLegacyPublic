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
		initializeGame();
	}

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
		#if html5
		// The blue HaxeFlixel preloader handles only the small default startup
		// assets. Load the title library after that preloader completes, before
		// entering the title or photosensitivity warning state.
		loadTitleLibrary(nextState);
		#else
		FlxG.switchState(() -> Type.createInstance(nextState, []));
		#end
	}

	#if html5
	function loadTitleLibrary(nextState:Class<FlxState>, attempt:Int = 0):Void
	{
		openfl.Assets.loadLibrary('title')
			.onComplete(function(_) {
				FlxG.switchState(() -> Type.createInstance(nextState, []));
			})
			.onError(function(error) {
				trace('Title asset library load failed (attempt ' + (attempt + 1) + '): ' + Std.string(error));
				if (attempt < 2)
				{
					haxe.Timer.delay(() -> loadTitleLibrary(nextState, attempt + 1), 400);
				}
				else
				{
					FlxG.switchState(() -> Type.createInstance(nextState, []));
				}
			});
	}
	#end
	}
}
