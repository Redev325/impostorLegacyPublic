var meltdownVideo:FunkinVideoSprite;
var outroCutscene:Bool = false;

function onLoad()
{
	videoCutscene('week1/meltdown');
}

function onCreatePost()
{
	// The HTML5 target uses the DOM-backed Html5Video implementation from
	// dialogue.hx. FunkinVideoSprite's browser update path is not reliable here
	// and can reach a null internal video object every frame. Keep the original
	// sprite implementation for native targets only.
	if (!IS_HTML5)
	{
		meltdownVideo = new FunkinVideoSprite(0, 0, false);
		insert(0, meltdownVideo);
		meltdownVideo.onFormat(() -> {
			meltdownVideo.camera = camOther;
			meltdownVideo.setGraphicSize(0, FlxG.height);
			meltdownVideo.updateHitbox();
			meltdownVideo.screenCenter();
		});
	}
	if (isStoryMode || !videoCheckStory || repeatedCutscenes) songEndCallback = meltEnd;
}

function onEvent(eventName, value1, value2)
{
	switch (eventName)
	{
		case 'Meltdown Video':
			if (boyfriend.curCharacter == 'bf-ghost') meltdownVid();
	}
}

function onUpdate()
{
	if (outroCutscene)
	{
		if (controls.BACK)
		{
			outroCutscene = false;
			#if html5
			Html5Video.stop();
			#else
			if (meltdownVideo != null)
			{
				meltdownVideo.destroy();
				meltdownVideo = null;
			}
			#end
			endSong();
		}
	}
	if (FlxG.keys.justPressed.Q && ClientPrefs.inDevMode)
	{
		setSongTime(143 * 1000);
		clearNotesBefore(Conductor.songPosition);
	}
}

function meltEnd()
{
	canPause = false;
	outroCutscene = true;
	camOther.bgColor = FlxColor.BLACK;
	
	videoCheckStory = false;
	PlayState.seenCutscene = false;
	videoCutscene('week1/post-week1', false, true, function() endSong());
	PlayState.seenCutscene = true;
	
	textFade();
}

function meltdownVid()
{
	if (ClientPrefs.lowQuality) return;
	if (IS_HTML5)
	{
		Html5Video.play(
			'assets/videos/week1/meltdownEnd.mp4',
			function() {},
			function() {},
			function() {}
		);
		return;
	}
	if (meltdownVideo != null && meltdownVideo.load(Paths.video(Paths.sanitize('week1/meltdownEnd'))))
		meltdownVideo.delayAndStart();
}
