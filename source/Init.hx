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

		@:nullSafety(Off)
	function loadStartupAssets():Void
	{
		final tasks:Array<Dynamic> = [
			{id: 'title:assets/data/introText.txt', kind: 'text', size: 994, label: 'intro text'},
			{id: 'title:assets/lang/english.json', kind: 'text', size: 33293, label: 'language'},
			{id: 'title:assets/fonts/vcr.ttf', kind: 'font', size: 142052, label: 'font'},
			{id: 'title:assets/fonts/vcr-srb.ttf', kind: 'font', size: 84752, label: 'font'},
			{id: 'title:assets/images/logoBumpin.png', kind: 'image', size: 1123455, label: 'title logo'},
			{id: 'title:assets/images/logoBumpin.xml', kind: 'text', size: 2111, label: 'title logo data'},
			{id: 'title:assets/images/alphabet.png', kind: 'image', size: 90659, label: 'alphabet'},
			{id: 'title:assets/images/alphabet.xml', kind: 'text', size: 52874, label: 'alphabet data'},
			{id: 'title:assets/images/cursor.png', kind: 'image', size: 1137, label: 'cursor'},
			{id: 'title:assets/images/menu/common/starFG.png', kind: 'image', size: 2114, label: 'foreground stars'},
			{id: 'title:assets/images/menu/common/starBG.png', kind: 'image', size: 1148, label: 'background stars'},
			{id: 'title:assets/images/menu/title/startText.png', kind: 'image', size: 360521, label: 'start text'},
			{id: 'title:assets/images/menu/title/startText.xml', kind: 'text', size: 4711, label: 'start text data'},
			{id: 'title:assets/images/menu/title/funkin.png', kind: 'image', size: 45365, label: 'title graphic'}
		];

		var totalBytes:Float = 0;
		for (task in tasks) totalBytes += task.size;
		final loadedBytes:Map<String, Float> = [];
		final fraction:Map<String, Float> = [];

		for (task in tasks)
		{
			loadedBytes.set(task.id, 0);
			fraction.set(task.id, 0);
		}

		var completed:Int = 0;
		var failed:Bool = false;

		function updateProgressFor(id:String, label:String, loaded:Float, total:Float):Void
		{
			if (failed) return;
			var ratio:Float = total > 0 ? loaded / total : 0;
			if (ratio > 1) ratio = 1;
			if (ratio < 0) ratio = 0;
			fraction.set(id, ratio);
			loadedBytes.set(id, loaded);
			var progressBytes:Float = 0;
			for (task in tasks) progressBytes += task.size * (fraction.get(task.id) ?? 0);
			final progress:Float = totalBytes > 0 ? progressBytes / totalBytes : 0;
			updateHtml5Loading(progress);
			updateHtml5LoadingStatus('Loading ' + label + '... ' + Std.int(progress * 100) + '%');
		}

		function completeTask(id:String):Void
		{
			fraction.set(id, 1);
			completed++;
			var progressBytes:Float = 0;
			for (task in tasks) progressBytes += task.size * (fraction.get(task.id) ?? 0);
			final progress:Float = totalBytes > 0 ? progressBytes / totalBytes : 0;
			updateHtml5Loading(progress);
			if (completed >= tasks.length)
			{
				updateHtml5Loading(1);
				updateHtml5LoadingStatus('Starting VS IMPOSTOR: LEGACY...');
				removeHtml5Loading();
				initializeGame();
			}
		}

		function failTask(id:String, label:String, error:Dynamic):Void
		{
			if (failed) return;
			failed = true;
			updateHtml5LoadingError('Failed to load ' + label + ': ' + Std.string(error));
		}

		for (task in tasks)
		{
			switch (task.kind)
			{
				case 'image':
					openfl.Assets.loadBitmapData(task.id)
						.onProgress(function(loaded:Int, total:Int) updateProgressFor(task.id, task.label, loaded, total))
						.onComplete(function(_) completeTask(task.id))
						.onError(function(error) failTask(task.id, task.label, error));
				case 'font':
					openfl.Assets.loadFont(task.id)
						.onProgress(function(loaded:Int, total:Int) updateProgressFor(task.id, task.label, loaded, total))
						.onComplete(function(_) completeTask(task.id))
						.onError(function(error) failTask(task.id, task.label, error));
				default:
					openfl.Assets.loadText(task.id)
						.onProgress(function(loaded:Int, total:Int) updateProgressFor(task.id, task.label, loaded, total))
						.onComplete(function(_) completeTask(task.id))
						.onError(function(error) failTask(task.id, task.label, error));
			}
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
