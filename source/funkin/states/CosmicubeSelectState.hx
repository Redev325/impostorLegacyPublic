package funkin.states;

import funkin.states.substates.CosmeticsSubstate;
import funkin.states.substates.CosmicubeSubState;

import funkin.objects.menu.*;
import funkin.data.CosmicubeData;
import funkin.input.TurboControl;

import flixel.group.FlxSpriteGroup;

using StringTools;

class CosmicubeSelectState extends AmongUIState
{
	public static var curSelect:Int = 0;
	
	var turboGroup:TurboControlGroup;
	var controlDOWN:TurboControl = TurboControl.fromControl('ui_down');
	var controlUP:TurboControl = TurboControl.fromControl('ui_up');
	
	var looksie:Bool = true;
	
	public var cards:FlxTypedSpriteGroup<CosmicubeCard> = new FlxTypedSpriteGroup();
	
	public override function create():Void
	{
		super.create();
		
		add(turboGroup = new TurboControlGroup());
		turboGroup.add(controlDOWN);
		turboGroup.add(controlUP);
		
		CosmicubeData.reload();
		
		// The locker preload is not required to render the Cosmicube selector.
		// On HTML5 it can request deferred cosmetic assets before the selector
		// has finished creating its own cards, so defer that preload until the
		// locker is actually opened.
		#if !html5
		CosmeticsSubstate.preloadForFreeplay();
		#end
		
		#if !html5
		DiscordClient.changePresence("Cosmicube Menu");
		#end
		
		var prevMod:Null<String> = Mods.currentModDirectory;
		Mods.currentModDirectory = null;
		
		persistentUpdate = true;
		
		#if !html5
		initStateScript();
		#end
		
		add(upperBar);
		add(backButton).revive();
		
		add(cards);
		cards.setPosition(40, upperBar.height + 40);
		cards.camera = FlxG.camera;
		cards.visible = true;
		cards.active = true;
		cards.zIndex = 5;
		
		// Always keep the built-in VS IMPOSTOR cube renderable on HTML5, even if
		// an asset-list lookup returns no cube IDs.
		var cubeIDs:Array<String> = CosmicubeData.cosmicubeList.copy();
		#if html5
		if (cubeIDs.length == 0)
		{
			final fallbackMeta:CosmicubeMetadata =
			{
				title: 'VS IMPOSTOR COSMICUBE',
				currency: 'beans',
				fileName: 'impostor',
				mod: null
			};
			CosmicubeData.cosmicubeList.push('impostor');
			CosmicubeData.cosmicubeMetas.set('impostor', fallbackMeta);
			CosmicubeData.cosmicubeItems.set('impostor', []);
			cubeIDs.push('impostor');
		}
		#end
		
		#if html5
		// The built-in VS IMPOSTOR cube is the only core cube on this build.
		// Create its card directly so the selector never depends on virtual
		// directory enumeration or an empty runtime cube list.
		var builtInMeta:CosmicubeMetadata = CosmicubeData.cosmicubeMetas.get('impostor');
		if (builtInMeta == null)
		{
			builtInMeta =
			{
				title: 'VS IMPOSTOR COSMICUBE',
				currency: 'beans',
				fileName: 'impostor',
				mod: null
			};
			CosmicubeData.cosmicubeMetas.set('impostor', builtInMeta);
			if (!CosmicubeData.cosmicubeList.contains('impostor')) CosmicubeData.cosmicubeList.push('impostor');
			if (!CosmicubeData.cosmicubeItems.exists('impostor')) CosmicubeData.cosmicubeItems.set('impostor', []);
		}
		
		Mods.currentModDirectory = null;
		cards.add(new CosmicubeCard(0, 0, builtInMeta));
		#else
		for (id in cubeIDs)
		{
			var meta:CosmicubeMetadata = (CosmicubeData.cosmicubeMetas.get(id) ?? CosmicubeData.fallbackMeta);
			
			Mods.currentModDirectory = meta.mod;
			
			cards.add(new CosmicubeCard(0, 0, meta));
		}
		#end
		
		Mods.currentModDirectory = prevMod;
		
		var bottomControls:AmongControls = new AmongControls([
			['arrow', 'select'], //select
			['enter', 'conf'], //conf
			['esc', 'back'], //back
			['tab', 'locker'] //locker
		], true);
		bottomControls.camera = camUpper;
		bottomControls.zIndex = 12;
		add(bottomControls);
		
		localCurrency = null;
		
		select(0);
		
		#if !html5
		scriptGroup.call('onCreatePost', []);
		#end
	}
	
	override function closeSubState():Void
	{
		super.closeSubState();
		
		lockMovement = false;
		
		for (card in cards) card.refresh();
	}
	
	override function update(elapsed:Float):Void
	{
		if (!lockMovement)
		{
			if (FlxG.keys.justPressed.TAB)
			{
				lockMovement = true;
				
				FlxG.sound.play(Paths.sound('scrollMenu'), .6);
				
				openSubState(new CosmeticsSubstate());
			}
			
			if (controls.UI_LEFT_P) selectLooksie(true);
			if (controls.UI_RIGHT_P) selectLooksie(false);
			if (controlUP.PRESSED) select(-1);
			if (controlDOWN.PRESSED) select(1);
			if (FlxG.mouse.wheel != 0) select(-FlxG.mouse.wheel);
			if (controls.ACCEPT) accept();
		}
		
		final cardSpacing:Float = 215;
		final topY:Float = (upperBar.height + 40);
		final bottomY:Float = (-cardSpacing * (cards.length - 1) - 40 + FlxG.height);
		
		final yOffset:Float = (cards.length > 1 ? FlxMath.remapToRange(curSelect, 0, cards.length - 1, topY, Math.min(topY, bottomY - 208)) : topY);
		
		final lerp:Float = Math.exp(-elapsed * 3);
		
		if (!lockMovement && FlxG.mouse.justPressed)
		{
			for (i => card in cards.members)
			{
				if (FlxG.mouse.overlaps(card.border))
				{
					select(i - curSelect);
					break;
				}
			}
		}
		
		for (i => card in cards.members)
		{
			card.y = MathUtil.fpsLerp(card.y, (cardSpacing * i) + yOffset, .2);
			card.color = FlxColor.interpolate(card.color, card.selected ? FlxColor.WHITE : 0x808080, lerp);
			
			card.looksie.alpha = MathUtil.fpsLerp(card.looksie.alpha, looksie && card.selected ? 1 : .5, .2);
			card.checkbox.alpha = MathUtil.fpsLerp(card.checkbox.alpha, !looksie && card.selected ? 1 : .5, .2);
			
			if (!lockMovement && card.selected && (FlxG.mouse.justMoved || FlxG.mouse.justPressed))
			{
				final overlapLooksie:Bool = FlxG.mouse.overlaps(card.looksie), overlapCheckbox:Bool = FlxG.mouse.overlaps(card.checkbox);
				
				if (overlapLooksie || overlapCheckbox)
				{
					selectLooksie(overlapLooksie);
					
					if (FlxG.mouse.justPressed) accept();
				}
			}
		}
		
		super.update(elapsed);
	}
	
	public function select(mod:Int = 0):Void
	{
		if (cards.length == 0)
		{
			curSelect = 0;
			return;
		}
		
		var lastCard:CosmicubeCard = cards.members[curSelect];
		
		FlxG.sound.play(Paths.sound('scrollMenu'), .6);
		
		curSelect = FlxMath.wrap(curSelect + mod, 0, cards.length - 1);
		
		var nextCard:CosmicubeCard = cards.members[curSelect];
		
		if (lastCard != null)
		{
			lastCard.select(false);
		}
		if (nextCard != null)
		{
			nextCard.select(true);
		}
	}
	
	public function selectLooksie(isIt:Bool):Void
	{
		if (looksie != isIt) FlxG.sound.play(Paths.sound('scrollMenu'), .6);
		
		looksie = isIt;
	}
	
	public function accept():Void
	{
		var card:CosmicubeCard = cards.members[curSelect];
		
		if (looksie)
		{
			lockMovement = true;
			
			FlxG.sound.play(Paths.sound('scrollMenu'), .6);
			
			openSubState(new CosmicubeSubState(card.id));
		}
		else
		{
			ClientPrefs.activeCosmicube = (card.activated ? null : card.id);
			
			for (card in cards) card.activate(ClientPrefs.activeCosmicube == card.id);
			
			FlxG.sound.play(Paths.sound(card.activated ? 'confirmMenu' : 'cancelMenu'), .6);
		}
	}
}
