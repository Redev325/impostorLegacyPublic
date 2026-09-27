package funkin.data;

typedef CosmicubeMetadata =
{
	var title:String;
	var ?currency:String;
	
	var ?mod:String;
	var ?fileName:String;
}

typedef ShopItemData =
{
	var ?requirement:Dynamic;
	var ?week:String;
	var ?song:String;
	var ?completionExcluded:Bool;
	
	var type:String;
	var price:Int;
	
	var ?title:String;
	var ?hint:String;
	var ?description:String;
	
	var node:NodeData;
	var ?fileName:String;
	
	var ?color:Dynamic;
	var ?icon:String;
	
	var ?currency:String;
}

enum ShopRequirement
{
	WEEK(week:String, ?accuracy:Float);
	SONG(song:String, ?accuracy:Float, ?rank:String);
	COMPLETION(percent:Float);
	GLOBAL_COMPLETION(percent:Float);
	UPDOG_SAVE;
	SCRIPTED;
	NONE;
}

class CosmicubeData
{
	public static var currentMeta(get, never):Null<CosmicubeMetadata>;
	public static var currentCurrency(get, never):String;
	public static var currentMoney(get, set):Int;
	
	public static var cosmicubeList:Array<String> = [];
	public static var cosmicubeMetas:Map<String, CosmicubeMetadata> = [];
	public static var cosmicubeItems:Map<String, Array<ShopItemData>> = [];
	
	public static var fallbackMeta:CosmicubeMetadata =
		{
			title: 'Unknown',
			currency: 'beans',
			fileName: 'idk'
		};
		
	public static function reload(hard:Bool = true):Void
	{
		if (!hard && cosmicubeList.length > 0) return;
		
		cosmicubeList.resize(0);
		cosmicubeMetas.clear();
		cosmicubeItems.clear();
		
		#if html5
		final dir:String = Paths.getCorePath('data/cosmicube');
		var files:Array<String> = FunkinAssets.readDirectory(dir);
		
		// HTML5 asset libraries do not expose filesystem directories. The base
		// cosmicube is known at build time, so make sure it is still discovered
		// when the runtime directory listing is empty.
		if (files.length == 0 && FunkinAssets.exists(haxe.io.Path.join([dir, 'impostor.json'])))
			files.push('impostor.json');
		
		for (file in files)
		{
			if (!file.endsWith('.json')) continue;
			
			final fileName:String = file.withoutExtension();
			final raw:Null<String> = FunkinAssets.getContent(haxe.io.Path.join([dir, file]));
			final meta:Null<CosmicubeMetadata> = FunkinAssets.parseJson5(raw);
			if (meta == null) continue;
			
			meta.fileName = fileName;
			meta.mod = null;
			
			cosmicubeList.push(fileName);
			cosmicubeMetas.set(fileName, meta);
			cosmicubeItems.set(fileName, getShopItems(haxe.io.Path.join([dir, fileName]), meta));
		}
		#else
		var directories:Array<String> = [Paths.mods(), Paths.getCorePath()];
		
		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods('$mod/'));
			
		for (dir in directories)
		{
			var modFolder:Null<String> = null;
			if (dir.startsWith(Paths.mods()))
			{
				modFolder = dir.substring(Paths.mods().length, dir.length - 1);
			}
			
			var cubeDir:String = dir + 'data/cosmicube/';
			
			if (!FunkinAssets.exists(cubeDir)) continue;
			
			for (file in FileSystem.readDirectory(cubeDir))
			{
				if (!file.endsWith('.json')) continue;
				
				var fileName:String = file.substr(0, file.indexOf('.json'));
				
				var meta:CosmicubeMetadata = haxe.Json.parse(File.getContent('$cubeDir/$file'));
				meta.fileName = fileName;
				meta.mod = modFolder;
				
				cosmicubeList.push(fileName);
				cosmicubeMetas.set(fileName, meta);
				cosmicubeItems.set(fileName, getShopItems('$cubeDir/$fileName/', meta));
			}
		}
		#end
	}
	static function getShopItems(dir:String, meta:CosmicubeMetadata):Array<ShopItemData>
	{
		final list:Array<ShopItemData> = [];
		
		#if html5
		var files:Array<String> = FunkinAssets.readDirectory(dir);
		
		// The HTML5 runtime can load the files synchronously, but it may not
		// expose virtual directory enumeration consistently. Fall back to the
		// current base cosmicube item index in that case.
		if (files.length == 0 && meta.fileName == 'impostor')
		{
			files = [
				'amongGf.json',
				'amongbf.json',
				'bf-ghost.json',
				'bf-stick.json',
				'bfairship.json',
				'bfballer.json',
				'bfmira.json',
				'bfpolus.json',
				'bfsauce.json',
				'bfsusreal.json',
				'blackp.json',
				'crab.json',
				'dog.json',
				'dripbf.json',
				'elliepet.json',
				'fall-guy.json',
				'fishus.json',
				'frankendog.json',
				'fribbit.json',
				'gf-ghost.json',
				'gf-stick.json',
				'gf-tuesday.json',
				'gfmira.json',
				'gfmira2.json',
				'gfpolus.json',
				'greenp.json',
				'ham.json',
				'hampton.json',
				'helicopter.json',
				'lilmungus.json',
				'magmate.json',
				'maroonplayable.json',
				'minicrewmate.json',
				'minigrey.json',
				'nuclearbomb.json',
				'pinkplayable.json',
				'redp.json',
				'slug.json',
				'slugmate.json',
				'snowball.json',
				'snowmate.json',
				'squig.json',
				'stickmin.json',
				'thenug.json',
				'tomong.json',
				'ufo.json',
				'upboy.json',
				'upgirl.json',
				'whitep.json',
				'yellowplayable.json'
			];
		}
		
		for (file in files)
		{
			if (!file.endsWith('.json')) continue;
			
			final fileName:String = file.withoutExtension();
			final raw:Null<String> = FunkinAssets.getContent(haxe.io.Path.join([dir, file]));
			final data:Null<ShopItemData> = FunkinAssets.parseJson5(raw);
			if (data == null) continue;
			
			data.currency = meta.currency;
			data.fileName = fileName;
			list.push(data);
		}
		#else
		if (!FunkinAssets.exists(dir) || !FunkinAssets.isDirectory(dir)) return list;
		
		for (file in FileSystem.readDirectory(dir))
		{
			if (!file.endsWith('.json')) continue;
			
			var fileName = file.substr(0, file.indexOf('.json'));
			
			var data:ShopItemData = haxe.Json.parse(File.getContent('$dir/$file'));
			data.currency = meta.currency;
			data.fileName = fileName;
			
			list.push(data);
		}
		#end
		
		return list;
	}
	inline static function get_currentMeta():CosmicubeMetadata
	{
		reload(false);
		
		return cosmicubeMetas.get(ClientPrefs.activeCosmicube);
	}
	
	inline static function get_currentCurrency():String
	{
		return (currentMeta?.currency ?? '');
	}
	
	static function get_currentMoney():Int
	{
		return getMoney(currentCurrency);
	}
	
	static function set_currentMoney(money:Int):Int
	{
		return setMoney(currentCurrency, money);
	}
	
	public static inline function getMoney(currency:Null<String>):Int
	{
		if (currency == null || currency.length == 0) return 0;
		
		if (!ClientPrefs.money.exists(currency)) ClientPrefs.money.set(currency, 0);
		
		return ClientPrefs.money.get(currency);
	}
	
	public static inline function setMoney(currency:Null<String>, money:Int):Int
	{
		if (currency == null || currency.length == 0) return 0;
		
		ClientPrefs.money.set(currency, money);
		
		return money;
	}
}
