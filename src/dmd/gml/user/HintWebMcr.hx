package dmd.gml.user;
import haxe.macro.Compiler;
import haxe.macro.Context;
#if (macro)
import sys.io.File;
#end

/**
 * ...
 * @author YellowAfterlife
 */
class HintWebMcr {
	public static macro function definedValue(s:String) {
		return macro $v{Context.definedValue(s)};
	}
	public static macro function loadCode(path:String) {
		return macro $v{File.getContent(path)};
	}
	#if (macro)
	public static function prebuild() {
		var path = Context.definedValue("js-header");
		Context.onAfterGenerate(function() {
			var out = Compiler.getOutput();
			var code = File.getContent(path) + File.getContent(out);
			File.saveContent(out, code);
		});
	}
	#end
}
