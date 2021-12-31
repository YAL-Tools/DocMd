package dmd.misc;

/**
 * ...
 * @author YellowAfterlife
 */
#if (js)
abstract StringDictionary<T>(Dynamic) {
	private static var exists_fn:Dynamic = untyped Object.prototype.hasOwnProperty;
	//
	public inline function new() this = js.Object.create(null);
	public inline function destroy():Void { }
	public function clear():Void {
		untyped __js__("for (var k in {0}) delete {0}[k]", this, this);
	}
	//
	public inline function exists(k:String) return untyped exists_fn.call(this, k);
	//
	public function get(k:String, d:T):T {
		return exists(k) ? rget(k) : d;
	}
	public inline function nget(k:String):Null<T> return rget(k);
	@:arrayAccess public inline function rget(k:String):T return untyped this[k];
	//
	public inline function set(k:String, v:T):Void {
		untyped this[k] = v;
	}
	@:arrayAccess private inline function chainset(key:String, val:T):T {
		set(key, val); return val;
	}
	//
	public inline function remove(k:String):Void {
		untyped __js__("delete {0}[{1}]", this, k);
	}
	public function keys():Array<String> {
		var arr:Array<String> = [];
		untyped __js__("for (var k in {0}) arr.push(k)", this);
		return arr;
	}
}
#else
import haxe.ds.StringMap;

abstract StringDictionary<T>(StringMap<T>) {
	public inline function new() {
		this = new StringMap();
	}
	public function get(k:String, d:T):T {
		return this.exists(k) ? this.get(k) : d;
	}
	public inline function nget(k:String):Null<T> {
		return this.get(k);
	}
	@:arrayAccess public inline function rget(k:String):T {
		return this.get(k);
	}
	public inline function set(k:String, v:T):Void {
		this.set(k, v);
	}
	@:arrayAccess private inline function chainset(key:String, val:T):T {
		set(key, val); return val;
	}
	public inline function remove(k:String):Void {
		this.remove(k);
	}
}
#end
