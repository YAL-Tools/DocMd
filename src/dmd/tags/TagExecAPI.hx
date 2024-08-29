package dmd.tags;
import dmd.nodes.DocMdPrinter;
import haxe.Rest;
import haxe.io.Path;
import hscript.Interp;
import sys.io.File;

/**
 * ...
 * @author YellowAfterlife
 */
class TagExecAPI {
	public static var global:Map<String, Dynamic> = null;
	public static function init(interp:Interp) {
		function getContent(path:String):String {
			var dir = DocMdSys.dir;
			var full = Path.normalize(dir + "/" + path);
			if (StringTools.startsWith(full, dir)) {
				return File.getContent(full);
			} else throw "Out of bounds";
		}
		function awaitChanges(path:String):Void {
			var full = DocMdSys.expandPath(path);
			if (full == null) return;
			DocMdSys.awaitChangesFor(full);
		}
		function renderAuto(dmd:String) {
			var setMap:Map<String, String> = null, cwd:String = null;
			#if sys
			setMap = DocMdSys.templateVars;
			var hadNavMenu = setMap.exists("navmenu");
			var navMenu = hadNavMenu ? setMap["navmenu"] : null;
			if (hadNavMenu) setMap.remove("navmenu");
			cwd = DocMdSys.currentDir;
			#end
			var result = DocMd.renderExt(dmd, null, setMap);
			#if sys
			if (hadNavMenu) setMap["navmenu"] = navMenu;
			#end
			return result;
		}
		var g = interp.variables;
		// std:
		g["Std"] = Std;
		g["Math"] = Math;
		g["String"] = String;
		g["StringTools"] = StringTools;
		g["Reflect"] = Reflect;
		g["EReg"] = EReg;
		g["StringBuf"] = StringBuf;
		g["Date"] = Date;
		g["DateTools"] = DateTools;
		
		g["trace"] = Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var r:String = null;
			for (v in args) {
				r = (r == null ? v : r + " " + v);
			}
			Sys.println(r);
		});
		g["print"] = Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			for (v in args) TagExec.next.add(v);
		});
		g["render"] = renderAuto;
		g["include"] = function(path:String) {
			awaitChanges(path);
			return DocMd.render(getContent(path));
		};
		
		g["sfmt"] = Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var fmt = args[0];
			var parts = fmt.split("%");
			var b = new StringBuf();
			b.add(parts[0]);
			for (i in 1 ... args.length) {
				var arg = args[i];
				b.add(arg);
				b.add(parts[i]);
			}
			return b.toString();
		});
		
		g["global"] = g;
		g["DocMd"] = {
			render: renderAuto,
			makeID: DocMd.makeID,
			addCodeTag: function(name:String, hdl:String->Dynamic) {
				TagCode.customTags.set(name, hdl);
			},
			printer: null,
			sectionStack: null,
			#if sys
			vars: DocMdSys.templateVars,
			#end
		};
		g["StringBufExt"] = StringBufExt;
		
		g["Bytes"] = haxe.io.Bytes;
		g["Base64"] = haxe.crypto.Base64;
		#if sys
		g["File"] = {
			getContent: getContent,
			awaitChanges: awaitChanges
		};
		#end
		global = g;
	}
}

@:keep class StringBufExt extends StringBuf {
	function __addFormat(args:Array<Dynamic>) {
		//trace(args);
		var fmt = args[0];
		var parts = fmt.split("%");
		this.add(parts[0]);
		for (i in 1 ... args.length) {
			var arg = args[i];
			this.add(arg);
			this.add(parts[i]);
		}
		return null;
	}
	public var addFormat:Rest<String>->Void;
	public function addString(s:String):Void add(s);
	public function addInt(i:Int):Void add(i);
	public function new() {
		super();
		addFormat = Reflect.makeVarArgs(__addFormat);
	}
}