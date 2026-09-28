package funkin;

import haxe.io.Bytes;
import haxe.Timer;

import openfl.media.Sound;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.URLRequest;
import openfl.net.URLLoader;
import openfl.utils.AssetType;
import openfl.display.BitmapData;
import openfl.Assets;
import lime.media.AudioBuffer;
import lime.net.HTTPRequest;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;

import funkin.backend.FunkinCache;
import funkin.backend.Difficulty;
import funkin.states.PlayState;

/**
 * backend for retrieving and caching assets
 */
@:nullSafety(Strict)
class FunkinAssets
{
	/**
	 * Handles the caching of assets collected through `Paths` 
	 */
	public static final cache:FunkinCache = new FunkinCache();

	static final HTML5_PRELOADED_LIBRARIES:Array<String> = ['title', 'mainmenu', 'menus'];
	static final HTML5_LIBRARIES:Array<String> = ['title', 'mainmenu', 'menus', 'embedded', 'gameplay', 'music', 'fonts'];

	#if html5
	static final html5LoadedLibraries:Map<String, Bool> = [];
	static var html5CurrentSongLibrary:Null<String> = null;
	static var html5SongChartText:Map<String, String> = [];
	static var html5SongSoundCache:Map<String, Sound> = [];
	#end

	#if html5
	/**
	 * Resolve an asset to the library that is actually ready for synchronous
	 * access in the HTML5 build.
	 *
	 * Lime's unqualified Assets.exists(path) can report an asset from a
	 * runtime-only library (for example gameplay:assets/images/currency/beans.png)
	 * even when the same asset also exists in a preloaded menu library. Choosing
	 * that runtime copy makes Assets.getBitmapData/getSound/getText throw the
	 * "exists, but only asynchronously" error. Prefer preloaded libraries first.
	 */
	/**
 	 * Loads HTML5 asset libraries that are intentionally kept out of the
 	 * startup preloader. This lets menus stay fast while still making
 	 * gameplay assets available synchronously once a song starts.
 	 */
	public static function loadHtml5Libraries(libraries:Array<String>, onComplete:Void->Void):Void
	{
		#if html5
			final queue:Array<String> = libraries.copy();
			
			function loadNext():Void
			{
				if (queue.length == 0)
				{
					onComplete();
					return;
				}
				
				final library:Null<String> = queue.shift();
				if (library == null)
				{
					loadNext();
					return;
				}
				
				if (html5LoadedLibraries.exists(library))
				{
					loadNext();
					return;
				}
				
				// Do not gate this on Assets.hasLibrary(). Deferred HTML5 libraries
				// are exactly the libraries that may not be registered until this call
				// resolves their manifest.
				Assets.loadLibrary(library).onComplete(function(loadedLibrary) {
					if (loadedLibrary == null)
					{
						Logger.log('HTML5 asset library could not be loaded: ' + library, ERROR);
						loadNext();
						return;
					}
					
					html5LoadedLibraries.set(library, true);
					loadNext();
				}).onError(function(error) {
					Logger.log('Failed to load HTML5 asset library ' + library + '\\nException: ' + error, ERROR);
					loadNext();
				});
			}
			
			loadNext();
		#else
			onComplete();
		#end
	}

	/**
	 * Loads the deferred library for exactly one song before PlayState starts.
	 * Story Mode and Freeplay both use this path on HTML5.
	 */
	public static function loadHtml5SongAssets(songName:String, onComplete:Void->Void, ?onError:Void->Void, ?difficulty:Int = -1)
	{
		#if html5
			final safeSongName:String = Paths.sanitize(songName);
			final libraryName:String = safeSongName == 'dlow' ? 'song_d_low' : 'song_' + safeSongName;

			function fail(reason:Dynamic):Void
			{
				Logger.log('Unable to load HTML5 song library $libraryName for $songName: $reason', ERROR);
				final callback:Void->Void = onError ?? function() {};
				callback();
			}

			if (html5LoadedLibraries.exists(libraryName))
			{
				html5CurrentSongLibrary = libraryName;
				onComplete();
				return;
			}

			// Each song has an explicit Lime library in Project.xml. Load that
			// library through the normal OpenFL/Lime asset pipeline, then mark it
			// as the current library so Paths can resolve its files synchronously.
			try
			{
				Assets.loadLibrary(libraryName).onComplete(function(loadedLibrary) {
					if (loadedLibrary == null)
					{
						fail('library returned null');
						return;
					}

					html5LoadedLibraries.set(libraryName, true);
					html5CurrentSongLibrary = libraryName;
					onComplete();
				}).onError(function(error) {
					fail(error);
				});
			}
			catch (e)
			{
				fail(e);
			}
		#else
			onComplete();
		#end
	}
	#if html5
	public static function getHtml5SongChart(songName:String, difficulty:Int):Null<String>
	{
		final songPath:String = Paths.sanitize(songName);
		return html5SongChartText.get(songPath + ':' + difficulty);
	}
	#end

	static function resolveHtml5AssetId(path:String, ?type:AssetType):Null<String>
	{
		// Respect an already-qualified Lime asset ID.
		if (path.indexOf(':') > 0)
		{
			return Assets.exists(path, type) ? path : null;
		}

		// Prefer the currently loaded song library for chart/audio/script paths.
		if (html5CurrentSongLibrary != null && Assets.hasLibrary(html5CurrentSongLibrary))
		{
			final id = html5CurrentSongLibrary + ':' + path;
			if (Assets.exists(id, type)) return id;
		}

		// Prefer libraries registered with the preloader.
		for (library in HTML5_PRELOADED_LIBRARIES)
		{
			if (!Assets.hasLibrary(library)) continue;
			final id = library + ':' + path;
			if (Assets.exists(id, type)) return id;
		}

		// Only fall back to runtime libraries when no preloaded copy exists.
		for (library in HTML5_LIBRARIES)
		{
			if (!Assets.hasLibrary(library)) continue;
			final id = library + ':' + path;
			if (Assets.exists(id, type)) return id;
		}

		// Finally accept a genuinely default/unqualified asset.
		return Assets.exists(path, type) ? path : null;
	}
	#end
	
	/**
	 * Safer alternative to directly using `haxe.Json.parse`
	 */
	public static function parseJson(content:String, ?pos:haxe.PosInfos):Null<Any>
	{
		try
		{
			return haxe.Json.parse(content);
		}
		catch (e)
		{
			Logger.log('failed to parse content\nException: ${e.message}', WARN, false, pos);
			return null;
		}
	}
	
	/**
	 * Parses a json using the json5 format.
	 */
	public static function parseJson5(content:String, ?pos:haxe.PosInfos):Null<Any>
	{
		try
		{
			#if json5hx
			return haxe.Json5.parse(content);
			#else
			return haxe.Json.parse(content);
			#end
		}
		catch (e)
		{
			Logger.log('failed to parse content\nException: ${e.message}', WARN, false, pos);
			return null;
		}
	}
	
	/**
	 * Retrieves the Bytes of a given file from its path
	 */
	public static function getBytes(path:String):Bytes
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) return File.getBytes(path);
		#end
		#if html5
		final resolved = resolveHtml5AssetId(path);
		if (resolved != null) return Assets.getBytes(resolved);
		#else
		if (Assets.exists(path)) return Assets.getBytes(path);
		#end
		throw 'Couldnt find file at path [$path]';
	}
	
	/**
	 * Retrieves the content of a given file from its path
	 */
	public static function getContent(path:String):String
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) return File.getContent(path);
		#end
		#if html5
		final resolved = resolveHtml5AssetId(path, TEXT);
		if (resolved != null) return Assets.getText(resolved);
		#else
		if (Assets.exists(path)) return Assets.getText(path);
		#end
		throw 'Couldnt find file at path [$path]';
	}
	
	/**
	 * Retrives a bitmap instance from path.
	 * 
	 * Will return null in the case it cannot be found.
	 */
	public static function getBitmapData(path:String, useCache:Bool = true):Null<BitmapData>
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) return BitmapData.fromFile(path);
		#end
		#if html5
		final resolved = resolveHtml5AssetId(path, IMAGE);
		if (resolved != null) return Assets.getBitmapData(resolved, useCache);
		return null;
		#else
		return Assets.exists(path, IMAGE) ? Assets.getBitmapData(path, useCache) : null;
		#end
	}
	
	/**
	 *	Returns whether a given path exists.
	 */
	public static function exists(path:String, ?type:AssetType):Bool
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) return true;
		#end
		#if html5
		return (type == null ? resolveHtml5AssetId(path) != null : resolveHtml5AssetId(path, type) != null);
		#else
		return Assets.exists(path, type);
		#end
	}
	
	/**
	 * Reads a given directory and returns all file names inside.
	 * 
	 * if it could not be found, an empty array will be returned.
	 */
	public static function readDirectory(directory:String):Array<String>
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		return FileSystem.exists(directory) ? FileSystem.readDirectory(directory) : []; // doing a check because i want this to maintain parity with ther assets variation
		#else
		if (directory.trim().length == 0) return [];
		
		final result:Array<String> = [];
		for (asset in Assets.list())
		{
			// Assets.list() returns library-qualified IDs such as
			// "menus:assets/data/weeks/week1.json". Strip the library prefix
			// before treating the remaining part as a virtual directory path.
			var virtualPath:String = asset;
			final colon:Int = virtualPath.indexOf(':');
			if (colon > 0) virtualPath = virtualPath.substr(colon + 1);
			
			final prefix:String = directory.endsWith('/') ? directory : '$directory/';
			if (!virtualPath.startsWith(prefix)) continue;
			
			final relative:String = virtualPath.substr(prefix.length);
			if (relative.length == 0) continue;
			
			final slash:Int = relative.indexOf('/');
			final child:String = slash == -1 ? relative : relative.substr(0, slash);
			if (child.length > 0 && !result.contains(child)) result.push(child);
		}
		return result;
		#end
	}
	
	public static function isDirectory(directory:String):Bool
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		return FileSystem.isDirectory(directory);
		#else
		if (directory.trim().length == 0) return false;
		final prefix:String = directory.endsWith('/') ? directory : '$directory/';
		for (asset in Assets.list())
		{
			var virtualPath:String = asset;
			final colon:Int = virtualPath.indexOf(':');
			if (colon > 0) virtualPath = virtualPath.substr(colon + 1);
			if (virtualPath.startsWith(prefix) && virtualPath.length > prefix.length) return true;
		}
		return false;
		#end
	}
	
	/**
	 * retrieves a flxgraphic instance from key.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 * @param allowGPU If true and is enabled in settings, the graphic will be cached on in video memory
	 */
	public static function getGraphicUnsafe(key:String, useCache:Bool = true, allowGPU:Bool = true):Null<FlxGraphic>
	{
		if (useCache && cache.currentTrackedGraphics.exists(key))
		{
			cache.localTrackedAssets.push(key);
			return cache.currentTrackedGraphics.get(key);
		}
		
		var bitmap:Null<BitmapData> = getBitmapData(key);
		
		if (bitmap != null)
		{
			return cache.cacheBitmap(key, bitmap, allowGPU);
		}
		
		return null;
	}
	
	/**
	 * retrieves a flxgraphic instance from key.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 * @param allowGPU If true and is enabled in settings, the graphic will be cached on in video memory
	 */
	public static function getGraphic(key:String, useCache:Bool = true, allowGPU:Bool = true):FlxGraphic
	{
		final graphic:Null<FlxGraphic> = getGraphicUnsafe(key, useCache, allowGPU);
		
		if (graphic != null)
		{
			return graphic;
		}
		
		Logger.log('graphic ($key) was not found. Returning flixel-logo instead');
		
		return FlxG.bitmap.add('flixel/images/logo/default.png');
	}
	
	/**
	 * Retrives a Sound instance from key.
	 * 
	 * If the sound could not be found, a beep sound will be given in place.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 */
	public static function getSound(key:String, useCache:Bool = true):Sound
	{
		final sound:Null<Sound> = getSoundUnsafe(key, useCache);
		
		if (sound != null)
		{
			return sound;
		}
		
		Logger.log('sound ($key) was not found. Returning beep instead');
		
		return FlxAssets.getSoundAddExtension('flixel/sounds/beep');
	}
	
	/**
	 * Retrives a Sound instance from key.
	 * 
	 * If the sound could not be found, null will be returned.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 */
	public static function getSoundUnsafe(key:String, useCache:Bool = true):Null<Sound>
	{
		if (useCache && cache.currentTrackedSounds.exists(key))
		{
			cache.localTrackedAssets.push(key);
			return cache.currentTrackedSounds.get(key);
		}
		
		var sound:Null<Sound> = null;
		
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(key)) sound = Sound.fromFile(key);
		#end
		#if html5
		if (sound == null)
		{
			#if html5
			if (html5SongSoundCache.exists(key))
			{
				sound = html5SongSoundCache.get(key);
			}
			else
			#end
			{
				#if html5
				final resolved = resolveHtml5AssetId(key, SOUND);
				if (resolved != null) sound = Assets.getSound(resolved, true);
				#else
				sound = null;
				#end
			}
		}
		#else
		if (sound == null && Assets.exists(key, SOUND)) sound = Assets.getSound(key, true);
		#end
		
		if (sound != null)
		{
			cache.cacheSound(key, sound);
		}
		
		return sound;
	}
	
	/**
	 * Returns the platform font name for a font asset.
	 *
	 * On HTML5, resolve through the preloaded library set first so a duplicate
	 * runtime-only font cannot trigger Lime's synchronous-access error.
	 */
	public static function getFontName(path:String):String
	{
		#if html5
		final resolved = resolveHtml5AssetId(path, FONT);
		if (resolved != null) return Assets.getFont(resolved).fontName;
		return path;
		#else
		return Assets.exists(path, FONT) ? Assets.getFont(path).fontName : path;
		#end
	}

	/**
	 * Constructs a Sound instance out of a `OGG Vorbis` file providing dramatically faster load times on larger files.
	 * 
	 * These do not support `.wav` and should be using sparingly
	 */
	public static function getVorbisSound(key:String):Null<Sound>
	{
		if (key.extension() != 'ogg') return null;
		
		#if !lime_vorbis
		// trace('gulp');
		return null;
		#else
		final vorbisFile = lime.media.vorbis.VorbisFile.fromFile(key);
		
		if (vorbisFile == null) return null;
		
		final buffer = lime.media.AudioBuffer.fromVorbisFile(vorbisFile);
		
		return Sound.fromAudioBuffer(buffer);
		#end
	}
}
