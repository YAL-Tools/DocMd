package;
import dmd.nodes.DocMdParser;
import dmd.nodes.DocMdPrinter;
import dmd.tags.TagCode;
#if hscript
import dmd.tags.TagExec;
#end
import haxe.ds.Map;
import dmd.misc.StringReader;
import dmd.misc.StringBuilder;
import gml.*;
import sys.FileSystem;
import sys.io.File;
import tags.*;
#if sys
import dmd.Misc;
#end
using StringTools;
using dmd.MiscTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMd {
	public static var genMode:GenMode = Nested;
	public static var autoAPI = false;
	public static var autoBR = false;
	public static function reset() {
		lastSections = new Map();
		autoAPI = false;
		autoBR = false;
		TagCode.reset();
		#if hscript
		TagExec.reset();
		#end
	}
	private static var rxStartItalic = ~/.\b_/g;
	private static var rxEndItalic = ~/_\b./g;
	public static var lastSections:Map<String, String> = new Map();
	public static function makeID(s:String) {
		s = s.replace(" ", "-");
		s = s.replace("'", "");
		s = ~/[^\w\-_]/g.replace(s, "");
		return s;
	}
	public static function render(dmd:String) {
		var nodes = DocMdParser.parse(dmd);
		var oldStyle = TagCode.nextStyle;
		TagCode.nextStyle = null;
		var html = DocMdPrinter.print(nodes);
		html = postfix(html);
		TagCode.nextStyle = oldStyle;
		return html;
	}
	static function postfix(rs:String):String {
		var sections = new Map<String, Bool>();
		~/<header id="(.+?)"/g.each(rs, function(rx:EReg) {
			sections[rx.matched(1)] = true;
		});
		
		// auto-link field calls:
		rs = (new EReg(
			'<span class="fd">(\\w+)</span>'
			+ '(\\s*<span class="op">\\(</span>)'
		, "g")).map(rs, function(rx:EReg) {
			var par = rx.matched(2);
			var fd = rx.matched(1);
			var at = rx.matchedPos().pos;
			at = rs.lastIndexOf('<span class="op">.', at);
			var till = rs.lastIndexOf('</span>', at);
			at = rs.lastIndexOf('>', till) + 1;
			var ctx = rs.substring(at, till);
			var id = ctx + "-" + fd;
			if (sections.exists(id)) {
				return '<a class="sf" href="#$id">$fd</a>$par';
			}
			return '<span class="sf">$fd</span>$par';
		});
		// auto-link identifiers:
		function procAutoAPI(cl:String):String {
			if (!autoAPI) return cl;
			return switch (cl) {
				case "uv": return "sv";
				case "uf": return "sf";
				case "fd": return "sf";
				default: return cl;
			}
		}
		// new X
		rs = ~/(<span class="kw">new<\/span>\s*)<span class="(\w+)">(\w+)<\/span>/g.map(rs, function(rx:EReg) {
			var cl = rx.matched(2);
			var fn = rx.matched(3);
			var ff = fn + "_new";
			if (sections.exists(ff)) {
				cl = procAutoAPI(cl);
				return rx.matched(1) + '<a class="$cl" href="#$ff">$fn</a>';
			}
			return rx.matched(0);
		});
		// X.Y
		rs = (new EReg(''
			+ '<span class="(\\w+)">(\\w+)</span>\\s*'
			+ '(<span class="op">\\.</span>\\s*)'
			+ '<span class="(\\w+)">(\\w+)</span>'
		, 'g')).map(rs, function(rx:EReg) {
			var mi = 0;
			var c1 = rx.matched(++mi);
			var w1 = rx.matched(++mi);
			var sep = rx.matched(++mi);
			var c2 = rx.matched(++mi);
			var w2 = rx.matched(++mi);
			var ff = w1 + "_" + w2;
			if (sections.exists(ff)) {
				c1 = procAutoAPI(c1);
				c2 = procAutoAPI(c2);
				return (sections.exists(w1)
					? '<a class="$c1" href="#$w1">$w1</a>'
					: '<span class="$c1">$w1</span>') + sep
					+ '<a class="$c2" href="#$ff">$w2</a>';
			}
			return rx.matched(0);
		});
		rs = ~/<span class="(sf|sv|kw|uf|uv)">(\w+)<\/span>/g.map(rs, function(rx:EReg) {
			var cl = rx.matched(1);
			var fn = rx.matched(2);
			if (sections.exists(fn)) {
				cl = procAutoAPI(cl);
				return '<a class="$cl" href="#$fn">$fn</a>';
			}
			return rx.matched(0);
		});
		rs = ~/<a class="header" id="([^\x22]+)"[^>]*>.*?<div[\s\S]+?(?:<\/div>|<div|$)/g.map(rs, function(rx:EReg) {
			var id = rx.matched(1);
			//trace(id, rx.matched(0));
			var ri = new EReg('<a class="([^"]+)" href="#$id">$id</a>', 'g');
			return ri.map(rx.matched(0), function(ri) {
				return '<span class="' + ri.matched(1) + '">$id</span>';
			});
		});
		return rs;
	}
	
	public static function collectVariables(dmd:String, setMap:Map<String, String>, ?fromDir:String) {
		// ```gml ...``` sets "tag:gml" variable and so on:
		static var rxCode = new EReg("^[ \t]*```(\\w+)", "gm");
		rxCode.each(dmd, function(r:EReg) {
			var tag = r.matched(1);
			setMap["tag:" + tag] = "1";
		});
		
		static var rxSet = new EReg("^([ \t]*)```set(?:md)?"
			+ "\\s+(\\S+)" // name
			+ "(?"
				+ "|[ \t]*(.*)```" // ```set name value```
				+ "|\\s+([\\s\\S]*?)^\\1```" // multi-line
		+ ")", "gm");
		rxSet.each(dmd, function(r:EReg) {
			var name = r.matched(2);
			var code = r.matched(3).trim();
			#if sys
			// `set name ./path` to store file contents in a variable
			if (fromDir != null && code.indexOf("\n") < 0 && code.startsWith("./")) {
				var rel = code.substring(2);
				code = Misc.getText(rel, fromDir);
				if (code == null) {
					Sys.println("Couldn't find " + rel);
					code = "";
				}
			}
			#end
			setMap.set(name, code);
			//trace(name, code, dmd);
		});
		
		for (name => code in setMap) {
			for (i in 0 ... 32) { // variables with variables inside
				var _code = code;
				for (name2 => code2 in setMap) {
					code = code.replace("%[" + name2 + "]", code2);
				}
				if (code == _code) break;
			}
			setMap[name] = code;
		}
	}
	
	public static function patchVariables(dmd:String, setMap:Map<String, String>, fromDir:String) {
		for (name => code in setMap) {
			dmd = dmd.replace("%[" + name + "]", code);
		}
		
		// %[./path] to inject a file on-spot
		#if sys
		if (fromDir != null) dmd = new EReg("(^\\s+)?%\\[\\./(.+?)\\]", "gm").map(dmd, function(r:EReg) {
			var rel = r.matched(2);
			var code = Misc.getText(rel, fromDir);
			if (code == null) {
				Sys.println("Couldn't find " + rel);
				return r.matched(0);
			} else {
				var tabs = r.matched(1);
				if (tabs != null) {
					code = tabs + code.replace("\n", "\n" +tabs);
				}
				return code;
			}
		});
		#end
		return dmd;
	}
	
	public static function renderExt(dmd:String, ?fromDir:String, ?setMap:Map<String, String>) {
		if (setMap == null) setMap = new Map();
		collectVariables(dmd, setMap, fromDir);
		
		dmd = patchVariables(dmd, setMap, fromDir);
		var defCode = setMap["tag:defcode"];
		TagCode.defaultKind = defCode;
		if (defCode != null) setMap["tag:" + defCode] = "1";
		
		//trace(dmd);
		if (setMap.exists("autobr")) DocMd.autoBR = true;
		if (setMap.exists("autoapi")) DocMd.autoAPI = true;
		if (setMap.exists("linear")) DocMd.genMode = Linear;
		var html = render(dmd);
		//trace(html);
		return html;
	}
}
enum GenMode {
	Nested;
	Linear;
	Visual;
}
enum Tag {
	MtFold;
	MtBold;
	MtItalic;
	MtStrike;
	MtSection;
	MtList(found:Array<Int>, kind:String);
}
