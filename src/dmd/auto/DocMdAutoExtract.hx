package dmd.auto;
import dmd.auto.DocMdAutoResolver;
import haxe.Json;
import haxe.macro.Compiler;
import haxe.macro.ExprTools;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdAutoExtract {
	public static function dmdPath(meta:MetaAccess, emt:ModuleType):Array<Dynamic> {
		var m = meta.extract(":dmdPath")[0];
		if (m == null) return null;
		var chain:Array<Dynamic> = [];
		if (m.params == null) {
			Context.error("Expected path slices for @:dmdPath", m.pos);
		} else for (p in m.params) {
			switch (p.expr) {
				case EField(e, fd): {
					var pair = DocMdAutoResolver.mapTwo(ExprTools.toString(e), fd, emt);
					if (pair != null) {
						chain.push([pair.id, pair.name]);
					} else Context.error("Invalid ref", p.pos);
				};
				case EConst(CIdent(id)): {
					var pair = DocMdAutoResolver.mapOne(id, emt);
					if (pair != null) {
						chain.push([pair.id, pair.name]);
					} else Context.error("Invalid ref", p.pos);
				};
				default: chain.push(ExprTools.getValue(p));
			}
		}
		return chain;
	}
	
	public static function dmdSetPath(meta:MetaAccess, ?def:Array<Dynamic>):Array<Dynamic> {
		var m = meta.extract(":dmdSetPath")[0];
		if (m == null) return def;
		var chain:Array<Dynamic> = [];
		if (m.params == null) {
			Context.error("Expected path slices for @:dmdPath", m.pos);
		} else for (p in m.params) {
			chain.push(ExprTools.getValue(p));
		}
		return chain;
	}
	
	public static function metaString(meta:MetaAccess, name:String):String {
		if (!meta.has(name)) return null;
		var m = meta.extract(name)[0];
		if (m.params == null || m.params[0] == null) return null;
		switch (m.params[0].expr) {
			case EConst(CString(s)): return s;
			default: return null;
		}
	}
	public static function metaFloat(meta:MetaAccess, name:String):Null<Float> {
		if (!meta.has(name)) return null;
		var m = meta.extract(name)[0];
		if (m.params == null || m.params[0] == null) return null;
		switch (m.params[0].expr) {
			case EConst(CFloat(s)): return Std.parseFloat(s);
			case EConst(CInt(s)): return Std.parseInt(s);
			default: return null;
		}
	}
	public static function metaSnake(meta:MetaAccess):Bool {
		if (Context.defined("sfgml_snake_case")) {
			return true;
		}
		return meta.has(":snakeCase");
	}
	static var isGMS23_leanParse = function(s:String) {
		if (s == null) return 0;
		return Std.parseInt(s) ?? 0;
	}
	static function isGMS23_calc() {
		if (Context.defined("sfgml.modern")) return true;
		var ver = Context.definedValue("sfgml_version");
		if (ver != null) {
			var vers = ver.split(".");
			var major = isGMS23_leanParse(vers[0]);
			if (major > 2) return true;
			if (major == 2 && isGMS23_leanParse(vers[1]) >= 3) return true;
			return false;
		}
		return false;
	}
	static function isGMS23() {
		static var result:Bool = null;
		if (result == null) result = isGMS23_calc();
		return result;
	}
	public static function metaStruct(meta:MetaAccess):Bool {
		if (isGMS23() && !Context.defined("sfgml_linear")) {
			return !meta.has(":gml.linear");
		} else {
			return meta.has(":gml.struct");
		}
	}
	public static function metaDotStatic(t:BaseType):Bool {
		static var isDotStatic:Bool = null;
		if (isDotStatic == null) {
			isDotStatic = isGMS23();
			if (isDotStatic) {
				var dsf = Context.definedValue("sfgml_dot_static");
				isDotStatic = dsf == null || (dsf != "0" && dsf != "false");
			}
		}
		if (isDotStatic) {
			return !t.isExtern || t.meta.has(":gml.dot_static");
		} else return false;
	}
	
	public static function docMeta(docRef:Array<String>, name:String):String {
		var doc = docRef[0];
		if (doc == null) return null;
		var p = doc.indexOf(name);
		if (p < 0) return null;
		var p0 = doc.lastIndexOf("\n", p);
		if (p0 < 0) {
			p0 = 0;
		} else if (p0 > 0 && doc.charCodeAt(p0 - 1) == "\r".code) p0--;
		var p1 = doc.indexOf("\n", p); if (p1 < 0) p1 = doc.length;
		var v = doc.substring(p + name.length, p1).trim();
		if (v.startsWith("<md>")) {
			var p2 = doc.indexOf("</md>", p1);
			if (p2 < 0) throw "Unclosed <md> tag";
			v = v.substring(4) + doc.substring(p1, p2);
			p1 = p2 + 5;
		}
		docRef[0] = doc.substring(0, p0) + doc.substring(p1);
		return v;
	}
	public static function docFloat(docRef:Array<String>, name:String):Null<Float> {
		var v = docMeta(docRef, name);
		return v != null ? Std.parseFloat(v) : null;
	}
	public static function docPath(docRef:Array<String>, tag:String):Array<Dynamic> {
		var json = docMeta(docRef, tag);
		if (json == null) return null;
		try {
			return Json.parse('[$json]');
		} catch (x:Dynamic) {
			return json.split("/");
		}
	}
	public static function docPreproc(docText:String, t:BaseType):String {
		docText = DocMd.patchVariables(docText, DocMdAutoResolver.templateVars, DocMdAutoResolver.templateDir);
		var typeMeta = t.meta;
		if (metaStruct(typeMeta)) {
			docText = ~/```gml:linear[\s\S]*?```/g.replace(docText, "");
			docText = docText.replace("```gml:struct", "```gml");
		} else {
			docText = ~/```gml:struct[\s\S]*?```/g.replace(docText, "");
			docText = docText.replace("```gml:linear", "```gml");
		}
		if (metaDotStatic(t)) {
			docText = ~/```gml:flatst[\s\S]*?```/g.replace(docText, "");
			docText = docText.replace("```gml:dotst", "```gml");
		} else {
			docText = ~/```gml:dotst[\s\S]*?```/g.replace(docText, "");
			docText = docText.replace("```gml:flatst", "```gml");
		}
		return docText;
	}
}
