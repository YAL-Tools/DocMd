package dmd.misc;
import dmd.misc.CharCode;
using StringTools;

/**
 * Offers a fast way of picking through contents of a string for parsing or else.
 * If faster, characters returned may instead be bytes, but substring should
 * still return an appropriately encoded string.
 * @author YellowAfterlife
 */
@:keep class StringReader {
	//
	private var source:String;
	public var pos:Int;
	public var length(default, null):Int;
	//
	public var loop(get, never):Bool;
	private inline function get_loop():Bool return (pos < length);
	//
	public inline function tell():Int return pos;
	public inline function seek(p:Int):Void pos = p;
	//
	public inline function new(src:String) {
		source = src;
		length = source.length;
		pos = 0;
	}
	public inline function close():Void source = null;
	//
	public inline function read():CharCode return source.fastCodeAt(pos++);
	public inline function peek(ofs:Int = 0):CharCode {
		return source.fastCodeAt(ofs != 0 ? pos + ofs : pos);
	}
	public function peekn(count:Int, ofs:Int = 0):String {
		return source.substr(ofs != 0 ? pos + ofs : pos, count);
	}
	
	public inline function skip(n:Int = 1):Void pos += n;
	public function skipIfEqu(c:Int) {
		if (peek() == c) {
			skip();
			return true;
		} else return false;
	}
	//
	public inline function get(p:Int):Int return source.fastCodeAt(p);
	public inline function substring(start:Int, till:Int):String {
		return source.substring(start, till);
	}
	public inline function substr(start:Int, length:Int):String {
		return source.substr(start, length);
	}
	//
	public function isLineStart(pos:Int):Bool {
		while (--pos >= 0) {
			var c = get(pos);
			switch (c) {
				case "\n".code, "\r".code: return true;
				case " ".code, "\t".code: {};
				default: return false;
			}
		}
		return true;
	}
	//
	public function skipLineSpaces() {
		while (loop) {
			switch (peek()) {
				case " ".code, "\t".code: pos++;
				default: return;
			}
		}
	}
	public function skipIdent() {
		while (loop) {
			var c = peek();
			if (inline c.isIdent1()) {
				skip();
			} else break;
		}
	}
	public function readIdent() {
		var start = pos;
		skipIdent();
		return substring(start, pos);
	}
	public function skipLine() {
		while (loop) {
			switch (peek()) {
				case "\n".code, "\r".code: return;
				default: skip();
			}
		}
	}
	//
	public function readTillAfter(end:Int) {
		var start = pos;
		while (loop && peek() != end) skip();
		return substring(start, pos++);
	}
	public function readTillAfterStr(end:String) {
		var start = pos;
		var endLen = end.length;
		while (loop) {
			if (peekn(endLen) == end) {
				var result = substring(start, pos);
				pos += endLen;
				return result;
			} else skip();
		}
		return substring(start, pos);
	}
	public function readBalanced(inc:Int, dec:Int, depth:Int = 1) {
		var start = pos;
		while (loop) {
			var c = read();
			if (c == inc) {
				depth++;
			} else if (c == dec) {
				if (--depth <= 0) {
					return substring(start, pos - 1);
				}
			}
		}
		return substring(start, pos);
	}
}