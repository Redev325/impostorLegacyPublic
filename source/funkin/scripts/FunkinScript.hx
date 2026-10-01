		#if html5
		// Legacy browser HScript files often call bare helpers like screenCenter() or
		// rely on reflective method invocation on JS objects. These functions are not
		// consistently available through Iris reflection, so expose a small
		// compatibility layer that guards nulls and calls the real Flixel methods.
		set('screenCenter', function(obj:Dynamic, ?axis:Dynamic):Dynamic {
			if (obj == null) return obj;
			if (Reflect.isFunction(obj.screenCenter))
			{
				if (axis == null) obj.screenCenter();
				else obj.screenCenter(cast axis);
			}
			return obj;
		});
		set('setAlpha', function(obj:Dynamic, value:Float):Dynamic {
			if (obj != null) obj.alpha = value;
			return obj;
		});
		set('safeCall', function(obj:Dynamic, name:String, ?args:Array<Dynamic>):Dynamic {
			if (obj == null || name == null || name.length == 0) return null;
			final fn:Dynamic = Reflect.field(obj, name);
			if (fn == null || !Reflect.isFunction(fn)) return null;
			return Reflect.callMethod(obj, fn, args ?? []);
		});
		#end
