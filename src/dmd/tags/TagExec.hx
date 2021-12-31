package dmd.tags;
import dmd.tags.TagExecAPI;
import haxe.ds.Map;
import haxe.CallStack;
import haxe.Rest;
#if hscript
import haxe.Constraints.Function;
import haxe.io.Path;
import hscript.Interp;
import hscript.Parser;
#if sys
import sys.io.File;
#end

/**
 * ...
 * @author YellowAfterlife
 */
class TagExec {
	static var parser:Parser;
	static var interp:Interp;
	public static var next:StringBuf = new StringBuf();
	public static function reset() {
		parser = null;
		interp = null;
	}
	public static function prepare() {
		if (parser != null) return;
		parser = new Parser();
		interp = new Interp();
		TagExecAPI.init(interp);
	}
	static function makeErrorBox(text:String) {
		return '<pre class="error">hscript error!\n' + StringTools.htmlEscape(text) + '</pre>';
	}
	static inline function callstack():String {
		return CallStack.toString(CallStack.exceptionStack());
	}
	
	public static function wrap(fn:Void->Dynamic):String {
		var last = next;
		next = new StringBuf();
		var result:String;
		try {
			var val = fn();
			if (val != null && Std.isOfType(val, String)) next.add(val);
			result = next.toString();
		} catch (x:Dynamic) {
			result = makeErrorBox(interp.posInfos() + " " + x + callstack());
		}
		next = last;
		return result;
	}
	
	public static function exec(s:String) {
		prepare();
		// we do a little wiggle to allow nested calls
		var last = next;
		next = new StringBuf();
		
		var html:String = null;
		var ast = try {
			parser.parseString(s);
		} catch (x:Dynamic) {
			html = makeErrorBox("[L" + parser.line + "] " + x + callstack());
			null;
		}
		
		if (ast != null) try {
			var result = interp.execute(ast);
			if (result != null && (result is String)) next.add(result);
			html = next.toString();
		} catch (x:Dynamic) {
			html = makeErrorBox(interp.posInfos() + " " + x + callstack());
		}
		next = last;
		return html;
	}
}
#end