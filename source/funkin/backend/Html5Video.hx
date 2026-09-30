package funkin.backend;

#if html5
import js.Browser;
#end

class Html5Video
{
	#if html5
	static var currentVideo:Dynamic = null;
	static var endCallback:Null<Void->Void> = null;
	static var errorCallback:Null<Void->Void> = null;
	static var finished:Bool = false;
	#end

	public static function play(path:String, onReady:Void->Void, onEnd:Void->Void, onError:Void->Void):Bool
	{
		#if html5
			stop();
			final video:Dynamic = Browser.document.createElement('video');
			currentVideo = video;
			endCallback = onEnd;
			errorCallback = onError;
			finished = false;

			video.preload = 'auto';
			video.autoplay = false;
			video.controls = false;
			video.loop = false;
			video.muted = false;
			video.setAttribute('playsinline', 'true');
			video.src = path;
			video.style.position = 'fixed';
			video.style.left = '0';
			video.style.top = '0';
			video.style.width = '100vw';
			video.style.height = '100vh';
			video.style.objectFit = 'contain';
			video.style.backgroundColor = 'black';
			video.style.zIndex = '99999';

			video.onloadeddata = function(_) {
				if (currentVideo != video || finished) return;
				onReady();
				try video.play() catch (e:Dynamic) {}
			};

			video.onended = function(_) {
				finish(endCallback);
			};

			video.onerror = function(_) {
				finish(errorCallback);
			};

			Browser.document.body.appendChild(video);
			return true;
		#else
			return false;
		#end
	}

	public static function skip():Void
	{
		#if html5
			finish(endCallback);
		#end
	}

	public static function stop():Void
	{
		#if html5
			final video = currentVideo;
			currentVideo = null;
			endCallback = null;
			errorCallback = null;
			finished = true;
			if (video != null)
			{
				try video.pause() catch (e:Dynamic) {}
				try
				{
					if (video.parentNode != null) video.parentNode.removeChild(video);
				}
				catch (e:Dynamic) {}
			}
		#end
	}

	public static function seek(delta:Float):Void
	{
		#if html5
			if (currentVideo == null) return;
			try
			{
				final duration:Float = currentVideo.duration;
				final target:Float = currentVideo.currentTime + delta;
				currentVideo.currentTime = Math.max(0, (Math.isNaN(duration) || duration <= 0) ? target : Math.min(target, duration));
			}
			catch (e:Dynamic) {}
		#end
	}

	#if html5
	static function finish(callback:Null<Void->Void>):Void
	{
		if (finished) return;
		finished = true;
		final video = currentVideo;
		currentVideo = null;
		final cb = callback;
		endCallback = null;
		errorCallback = null;

		if (video != null)
		{
			try video.pause() catch (e:Dynamic) {}
			try
			{
				if (video.parentNode != null) video.parentNode.removeChild(video);
			}
			catch (e:Dynamic) {}
		}

		if (cb != null) cb();
	}
	#end
}
