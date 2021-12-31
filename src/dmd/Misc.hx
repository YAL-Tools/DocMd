package dmd;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author YellowAfterlife
 */
class Misc {
	#if neko
	static var moduleDir = Path.directory(neko.vm.Module.local().name);
	static var loaderDir = neko.vm.Module.local().loader().getPath()[0];
	#else
	#if macro
	static var macroPath:String = {
		var p = haxe.macro.Context.currentPos();
		var dmdSys = haxe.macro.Context.resolvePath("DocMdSys.hx");
		var binPath = Path.join([Path.directory(dmdSys), "..", "bin"]);
		binPath;
	};
	#end
	static var mainPath = {
		try {
			Path.directory(Sys.executablePath());
		} catch (x:Dynamic) {
			".";
		};
	}
	#end
	public static function resolve(path:String, ?dir:String):String {
		var full:String;
		do {
			if (dir != null) {
				full = Path.join([dir, path]);
				if (FileSystem.exists(full)) break;
			}
			full = path;
			if (FileSystem.exists(full)) break;
			#if neko
			full = Path.join([moduleDir, path]);
			if (FileSystem.exists(full)) break;
			full = Path.join([loaderDir, path]);
			if (FileSystem.exists(full)) break;
			#else
			#if macro
			full = Path.join([macroPath, path]);
			if (FileSystem.exists(full)) break;
			#end
			full = Path.join([mainPath, path]);
			if (FileSystem.exists(full)) break;
			#end
			return null;
		} while (false);
		return full;
	}
	public static function getText(path:String, ?dir:String) {
		var full = resolve(path, dir);
		if (full == null) return null;
		//
		try {
			return File.getContent(full);
		} catch (_:Dynamic) {
			return null;
		}
	}
}
