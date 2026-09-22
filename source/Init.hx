package;

import funkin.FunkinAssets;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.utils.Assets;

import funkin.backend.MusicBeatState;

/**
 * Initiation state that prepares backend classes and returns to menus when finished.
 */
@:nullSafety(Strict)
class Init extends FlxState
{
	#if html5
	var titleLoadingText:Null<FlxText>;
	var titleLoadingPercent:Float = 0;
	#end

	override public function create():Void
	{
		super.create();
		initializeGame();
	}

	function initializeGame():Void
	{
		// Load settings/save before any state assets are needed.
		funkin.input.Controls.init();
		ClientPrefs.load();
		funkin.data.Highscore.load();

		if (FlxG.save.data.weekCompleted != null)
			funkin.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxSprite.defaultAntialiasing = ClientPrefs.globalAntialiasing;

		// Discord RPC disabled for HTML5.

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

		#if html5
		beginTitleLibraryLoad();
		#else
		finishInitialization();
		#end
	}

	#if html5
	function beginTitleLibraryLoad():Void
	{
		final loadingText:FlxText = new FlxText(
			0,
			FlxG.height * 0.5 - 20,
			FlxG.width,
			'Loading title assets... 0%',
			20
		);
		loadingText.setFormat(null, 20, FlxColor.WHITE, CENTER);
		titleLoadingText = loadingText;
		add(loadingText);

		// The HaxeFlixel blue preloader has already completed. This is a
		// separate, post-preloader library load and does not replace it.
		Assets.loadLibrary('title')
			.onProgress(function(loaded:Int, total:Int)
			{
				titleLoadingPercent = total > 0 ? (loaded / total) * 100 : 100;

				if (titleLoadingText != null)
				{
					titleLoadingText.text = 'Loading title assets... ' + Math.round(titleLoadingPercent) + '%';
				}
			})
			.onError(function(error:Dynamic)
			{
				if (titleLoadingText != null)
					titleLoadingText.text = 'Title assets failed to load. Please reload the page.';

				trace('ERROR: Failed to load title library: ' + error);
			})
			.onComplete(function(_)
			{
				finishInitialization();
			});
	}
	#end

	function finishInitialization():Void
	{
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

		// Keep the title music key tracked; HTML5 playback itself remains
		// gesture-gated in TitleState.
		FunkinAssets.cache.currentTrackedSounds.addPermanentKey('assets/music/freakyMenu.ogg');

		final nextState:Class<FlxState> =
			Main.startMeta.skipSplash || !ClientPrefs.toggleSplashScreen
				? Main.startMeta.initialState
				: Splash;

		FlxG.switchState(() -> Type.createInstance(nextState, []));
	}
}
