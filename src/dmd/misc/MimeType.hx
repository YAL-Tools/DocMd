package dmd.misc;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.ds.Map;
import haxe.io.Path;
import sys.io.File;

/**
 * ...
 * @author YellowAfterlife
 */
class MimeType {
	public static inline var defValue:String = "application/octet-stream";
	public static var map:Map<String, String> = new Map();
	public static function get(ext:String) {
		var r = map[ext.toLowerCase()];
		return r != null ? r : defValue;
	}
	public static function init() {
		var path = Path.directory(Sys.programPath()) + "/node-mime.json";
		var data:DynamicAccess<Array<String>> = Json.parse(File.getContent(path));
		for (mt in data.keys()) {
			var xs = data[mt];
			for (x in xs) map[x] = mt;
		}
	}
}
