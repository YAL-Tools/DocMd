package dmd.tags;
import dmd.nodes.DocMdPos;
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
	public static function store() {
		return { parser: parser, interp: interp };
	}
	public static function restore(obj){
		parser = obj.parser;
		interp = obj.interp;
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
	static inline function handleError(x:Dynamic){
		var cs = callstack();
		var inf = interp.posInfos();
		var infs = "[" + inf.fileName + ":" + inf.lineNumber + "]";
		var msg = infs + " " + x + cs;
		#if sys
		Sys.println(msg);
		#else
		trace(msg);
		#end
		return makeErrorBox(msg);
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
			return handleError(x);
		}
		next = last;
		return result;
	}
	
	public static function exec(s:String, origin:DocMdPos) {
		prepare();
		var global = dmd.tags.TagExecAPI.global;
		if (global != null) {
			var printer = dmd.nodes.DocMdPrinter.current;
			global["DocMd"].printer = printer;
			global["DocMd"].sectionStack = printer.sectionStack;
		}
		// we do a little wiggle to allow nested calls
		var last = next;
		next = new StringBuf();
		
		var html:String = null;
		var ast = try {
			parser.line += origin.row;
			parser.parseString(s, origin.file);
		} catch (x:Dynamic) {
			html = handleError(x);
			null;
		}
		
		if (ast != null) try {
			var result = interp.execute(ast);
			if (result != null && (result is String)) next.add(result);
			html = next.toString();
		} catch (x:Dynamic) {
			html = handleError(x);
		}
		next = last;
		return html;
	}
}
#end