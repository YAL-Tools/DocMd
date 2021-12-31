package dmd.gml;
import haxe.ds.Map;
import sys.io.File;
using dmd.MiscTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlGen {
	public static function main() {
		//
		var found:Map<String, Bool> = new Map();
		var out:Array<String> = [];
		function proc(path:String) {
			var d = File.getContent(path);
			~/^(\w+\b) ?(?:[^(]|$)/gm.each(d, function(e:EReg) {
				var name = e.matched(1);
				if (found.exists(name)) return;
				found.set(name, true);
				out.push(name);
			});
		}
		proc("src/gml/v2/fnames");
		proc("src/gml/v1/fnames");
		//
		var code = File.getContent("src/gml/GmlData.hx");
		code = ~/".*("; \/\/ auto)/g.replace(code, '"' + out.join("\\n") + "$1");
		File.saveContent("src/gml/GmlData.hx", code);
		//
	}
}
