package dmd.misc;
import haxe.extern.Rest;

/**
 * ...
 * @author YellowAfterlife
 */
class StringBuilder extends StringBuf {
	
	public function new() {
		super();
	}
	public inline function close() { }
	//
	public inline function addString(s:String):Void {
		this.add(s);
	}
	public inline function addInt(i:Int):Void {
		this.add(i);
	}
	//
	/** (format, ...args) */
	public function addFormat(fmt:String, args:Rest<Dynamic>) {
		var data:Array<String> = formatCache.rget(fmt);
		var i:Int, n:Int;
		if (data == null) {
			data = [];
			var start = 0;
			i = 0; n = fmt.length;
			while (i < n) {
				if (fmt.charCodeAt(i) == "%".code) {
					if (i > start) data.push(fmt.substring(start, i));
					data.push(fmt.substr(i, 2));
					i += 2; start = i;
				} else i += 1;
			}
			if (i > start) data.push(fmt.substring(start, i));
			formatCache.set(fmt, data);
		}
		//
		i = -1;
		n = data.length;
		var argi = 0;
		while (++i < n) {
			var arg:String = data[i];
			if (arg.charCodeAt(0) == "%".code) {
				var fn = formatMap.rget(arg);
				if (fn != null) {
					if (!formatMapBlank.get(arg, false)) {
						if (argi >= args.length) throw 'Not enough arguments for `$fmt`';
						fn(this, args[argi++], argi);
					} else fn(this, null, -1);
				} else throw '$arg is not a known format.';
			} else addString(arg);
		}
		if (argi < args.length) throw 'Too many arguments for `$fmt`';
		//
		return null;
	}
	
	private static var formatCache:StringDictionary<Array<String>> = new StringDictionary();
	
	public static var formatMap:StringDictionary<StringBuilder_addFormat_func> = formatMap_init();
	public static var formatMapBlank:StringDictionary<Bool> = new StringDictionary();
	private static function formatMap_init() {
		var r = new StringDictionary();
		r.set("%s", function(b:StringBuilder, s:Dynamic, i:Int) {
			if (Std.isOfType(s, String)) {
				b.addString(s);
			} else throw 'Expected a string for arg#$i';
		});
		r.set("%d", function(b:StringBuilder, v:Dynamic, i:Int) {
			if (Std.isOfType(v, Int)) {
				b.addInt(v);
			} else throw 'Expected an int for arg#$i';
		});
		r.set("%f", function(b:StringBuilder, v:Dynamic, i:Int) {
			if (Std.isOfType(v, Float)) {
				b.add(v);
			} else throw 'Expected an int for arg#$i';
		});
		r.set("%c", function(b:StringBuilder, v:Dynamic, i:Int) {
			if (Std.isOfType(v, Int)) {
				b.addInt(v);
			} else throw 'Expected a char for arg#$i';
		});
		r.set("%t", function(b:StringBuilder, v:Dynamic, i:Int) {
			if (Std.isOfType(v, Int)) {
				for (i in 0 ... v) b.addChar("\t".code);
			} else throw 'Expected a tab count for arg#$i';
		});
		return r;
	}
}

typedef StringBuilder_addFormat_rest = (format:String, rest:Rest<Dynamic>)->Void;
typedef StringBuilder_addFormat_func = (b:StringBuilder, val:Dynamic, i:Int)->Void;
