package funkin.backend;

@:nullSafety
class FallbackState extends MusicBeatState
{
	final warningMessage:String;
	
	final continueCallback:Void->Void;
	
	public function new(warningMessage:String, continueCallback:Void->Void)
	{
		this.continueCallback = continueCallback;
		this.warningMessage = warningMessage;
		super();
	}
	
	override function create()
	{
		var bg = new FlxSprite().loadGraphic(Paths.image('uhoh'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);
		
		var error = new FlxText(0, 0, 0, 'ERROR', 46);
		error.setFormat(Paths.DEFAULT_FONT, 46, FlxColor.RED, LEFT, OUTLINE, FlxColor.BLACK);
		error.screenCenter(X);
		error.y = 25;
		add(error);
		FlxTween.tween(error, {y: error.y + 45}, 2, {ease: FlxEase.sineInOut, type: PINGPONG});
		
		// Keep the full report on-screen even when the JavaScript callstack is
		// very large. The previous centered 32px block could push the most
		// important "Exception caught:" line above the viewport.
		var text = new FlxText(25, 78, FlxG.width - 50, warningMessage, 18);
		text.setFormat(Paths.DEFAULT_FONT, 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		text.y = 78;
		add(text);
		
		var text = new FlxText(0, FlxG.height - 25 - 32, FlxG.width, 'Press Confirm to continue.', 32);
		text.setFormat(Paths.DEFAULT_FONT, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(text);
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.ACCEPT)
		{
			persistentUpdate = false;
			continueCallback();
		}
	}
}
