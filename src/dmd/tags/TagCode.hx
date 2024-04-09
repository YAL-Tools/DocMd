package dmd.tags;
import dmd.gml.GmlAPI;
import dmd.gml.GmlVersion;
import dmd.gml.HintGML;
import haxe.ds.Map;
import dmd.misc.StringBuilder;
import gml.*;
import DocMd.render;
using StringTools;
using dmd.MiscTools;

/**
 * ...
 * @author YellowAfterlife
 */
class TagCode {
	public static var defaultKind:String = null;
	public static var nextStyle:String;
	public static var nextGmlHint:String = null;
	public static var customTags:Map<String, String->Dynamic> = new Map();
	public static function reset() {
		nextStyle = null;
		nextGmlHint = null;
		customTags = new Map();
	}
	private static inline var rsPre = "^\\s*";
	private static inline var rsVal = "\\s+(\\S+)";
	private static inline var rsAlt = "(?:\\s+alt:\\s*(.+))?";
	private static inline var rsSub = "(?:\\s+sub:\\s*(.+))?";
	private static inline var rsPost = "\\s*$";
	public static function add(r:StringBuilder, kind:String, code:String) {
		var s3:String;
		var ptag = true;
		switch (kind) {
			case "gmlapi":
				code = code.trim();
				if (code.indexOf("\n") < 0) {
					s3 = Misc.getText(code);
					if (s3 != null) code = s3;
				}
				GmlAPI.loadEntries(code);
				return;
			case "gmlres", "gmlassets":
				code = code.trim();
				if (code.indexOf("\n") < 0) {
					s3 = Misc.getText(code);
					if (s3 != null) code = s3;
				}
				GmlAPI.loadAssets(code);
				return;
			case "gmlkeywords": {
				~/(\w+)/g.each(code, function(rx:EReg) {
					GmlAPI.keywords.set(rx.matched(1), true);
				});
				return;
			};
			case "gmlhint": {
				nextGmlHint = code;
				return;
			};
			case "codecss":
				nextStyle = ~/[\r\n\t]/g.replace(code.trim(), " ");
				return;
			case "set"|"setmd"|"hide": return;
			case "exec": ptag = false;
		}
		var cf = customTags[kind];
		if (cf == null && kind.endsWith("md")) {
			cf = customTags[kind.substring(0, kind.length - 2)];
		}
		if (cf != null) ptag = true;
		//if (r.length > 0 && ptag) r.addString("</p>");
		function procCode(code:String) {
			var p = code.indexOf(">");
			if (p < 0) return code;
			if (nextStyle != null) {
				code = code.substring(0, p)
					+ ' style="' + nextStyle + '"' +
					code.substring(p);
				nextStyle = null;
			}
			return code;
		}
		
		if (kind == "" && defaultKind != null) kind = defaultKind;
		
		switch (kind) {
			case "quote": {
				r.addFormat("<blockquote>%s</blockquote>", code.htmlEscape());
			};
			case "quotemd": {
				r.addFormat("<blockquote>%s</blockquote>", render(code));
			};
			case "gml": {
				code = code.replace("\t", "    ");
				#if sys
				if (DocMdSys.templateVars.exists("GMS1")) {
					code = code.replace("@'", "'");
					code = code.replace('@"', '"');
				}
				#end
				var v = GmlVersion.detect(code);
				if (v != 0) {
					HintGML.version = v;
					code = procCode(HintGML.proc(code, "gmlmd", true, nextGmlHint, GML));
					nextGmlHint = null;
					r.addString(code);
				} else { // not valid GML
					code = "<pre>" + HintGML.unindent(code).htmlEscape() + "</pre>";
					r.addString(procCode(code));
				}
			};
			case "lua": {
				HintGML.version = 2;
				code = procCode(HintGML.proc(code, "lua", true, null, Lua));
				r.addString(code);
			};
			case "ahk": {
				HintGML.version = 2;
				code = procCode(HintGML.proc(code, "ahk", true, null, AHK));
				r.addString(code);
			};
			case "raw": {
				r.addString(code);
			};
			#if hscript
			case "exec": { // exec ...hscript
				r.addString(TagExec.exec(code));
			};
			#end
			default: {
				#if hscript
				if (cf != null) {
					var v = TagExec.wrap(() -> cf(code));
					if (v != null && Std.isOfType(v, String)) r.addString(v);
				} else
				#end
				{
					code = "<pre>" + HintGML.unindent(code).htmlEscape() + "</pre>";
					r.addString(procCode(code));
				}
			};
		}
		//if (ptag) r.addString("<p>");
	}
}
