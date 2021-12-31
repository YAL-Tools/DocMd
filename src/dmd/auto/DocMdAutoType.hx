package dmd.auto;
import dmd.auto.DocMdAutoExtract;
import haxe.io.Path;
import haxe.macro.Type;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdAutoType {
	#if gml
	public static inline var pkgSep:String = "_";
	#else
	public static inline var pkgSep:String = ".";
	#end
	public static function printBaseTypePath(bt:BaseType):String {
		if (bt.meta.has(":native")) {
			var path = DocMdAutoExtract.metaString(bt.meta, ":native");
			#if gml
			path = StringTools.replace(path, ".", "_");
			#end
			return path;
		} else {
			var b = new StringBuf(), sep = false;
			#if !sfgml_doc_is_toplevel
			for (s in bt.pack) {
				if (sep) b.add(pkgSep); else sep = true;
				b.add(s);
			}
			#end
			if (sep) b.add(pkgSep); else sep = true;
			var btSnakeCase = DocMdAutoExtract.metaSnake(bt.meta);
			b.add(btSnakeCase ? DocMdAutoTools.toSnakeCase(bt.name) : bt.name);
			return b.toString();
		}
	}
	public static function printBaseTypeDocName(bt:BaseType):String {
		if (bt.meta.has(":docName")) return DocMdAutoExtract.metaString(bt.meta, ":docName");
		if (bt.meta.has(":native")) {
			var s = DocMdAutoExtract.metaString(bt.meta, ":native");
			var p = s.lastIndexOf(".") + 1;
			return s.substring(p);
		}
		var btSnakeCase = DocMdAutoExtract.metaSnake(bt.meta);
		return btSnakeCase ? DocMdAutoTools.toSnakeCase(bt.name) : bt.name;
	}
	public static function printModuleTypePath(mt:ModuleType):String {
		return printBaseTypePath(baseTypeForModuleType(mt));
	}
	static var printFieldPath_isGML:Null<Bool> = null;
	public static function printFieldPath(name:String, kind:DocMdAutoFieldKind, meta:MetaAccess, bt:BaseType, ?btPath:String):String {
		var exp = DocMdAutoExtract.metaString(meta, ":expose");
		if (exp != null) return exp;
		if (meta.has(":native")) name = DocMdAutoExtract.metaString(meta, ":native");
		inline function ensureBtPath():Void {
			if (btPath == null) btPath = printBaseTypePath(bt);
		}
		var btSnakeCase:Bool;
		inline function procName():String {
			btSnakeCase = DocMdAutoExtract.metaSnake(bt.meta);
			if (btSnakeCase || meta.has(":snakeCase")) return DocMdAutoTools.toSnakeCase(name);
			return name;
		}
		if (DocMdAutoExtract.metaStruct(bt.meta)) switch (kind) {
			case InstVar, InstFunc: return procName();
			case InstVarFQ: {
				ensureBtPath();
				return btPath + "." + procName();
			};
			case StaticVar, StaticFunc if (DocMdAutoExtract.metaDotStatic(bt)): {
				ensureBtPath();
				return btPath + "." + procName();
			};
			case EnumCtr if (bt.meta.has(":nativeGen")): {
				var isScript = printFieldPath_isGML;
				if (isScript == null) {
					var path = haxe.macro.Compiler.getOutput();
					if (Path.extension(path) == "_") path = Path.withoutExtension(path);
					if (Path.extension(path) == "gml") {
						isScript = true;
					} else if (Path.extension(path) == "yy") {
						var outDir = Path.directory(path);
						var outParent = Path.directory(outDir);
						isScript = Path.withoutDirectory(outParent) == "scripts";
					} else isScript = false;
					printFieldPath_isGML = isScript;
				}
				if (isScript) {
					ensureBtPath();
					return btPath + "." + procName();
				}
			};
			case Constructor: {
				ensureBtPath();
				return "new " + btPath;
			};
			default:
		}
		//
		btSnakeCase = DocMdAutoExtract.metaSnake(bt.meta);
		if (btSnakeCase || meta.has(":snakeCase")) name = DocMdAutoTools.toSnakeCase(name);
		ensureBtPath();
		if (btPath == "") return name;
		return btPath + pkgSep + name;
	}
	
	public static function baseTypeForType(t:Type):{baseType:BaseType, params:Array<Type>} {
		return switch (t) {
			case null: return null;
			case TEnum(_.get() => bt, tp): return {baseType: bt, params: tp};
			case TInst(_.get() => bt, tp): return {baseType: bt, params: tp};
			case TType(_.get() => bt, tp): return {baseType: bt, params: tp};
			case TAbstract(_.get() => bt, tp): return {baseType: bt, params: tp};
			default: return null;
		}
	}
	public static function baseTypeForModuleType(mt:ModuleType):BaseType {
		if (mt == null) return null;
		return switch (mt) {
			case TClassDecl(_.get() => ct): ct;
			case TEnumDecl(_.get() => et): et;
			case TTypeDecl(_.get() => tt): tt;
			case TAbstract(_.get() => at): at;
			default: null;
		}
	}
	
	public static function print(t:Type, ?def:String):String {
		if (t == null) return def;
		var pair = baseTypeForType(t);
		if (pair == null) return def;
		var bt = pair.baseType;
		var tp = pair.params;
		
		#if gml
		switch (bt.module) {
			case "StdTypes": switch (bt.name) {
				case "Int": return "int";
				case "Float": return "number";
				case "Bool": return "bool";
				case "Void": return "void";
			};
			case "String": return "string";
			case "Array": {
				var tp0 = print(tp[0]);
				return tp0 != null ? 'array<$tp0>' : 'array';
			};
		}
		#end
		
		var docName = DocMdAutoExtract.metaString(bt.meta, ":docName");
		if (docName != null) {
			if (tp.length > 0) {
				if (docName.indexOf("$") >= 0) {
					for (i in 0 ... tp.length) {
						docName = docName.replace("$" + (i + 1), print(tp[i], "any"));
					}
				} else {
					docName += "<";
					var sep = false;
					for (tpt in tp) {
						if (sep) docName += ","; else sep = true;
						docName += print(tpt, "any");
					}
					docName += ">";
				}
			}
			return docName;
		}
		
		#if gml
		if (bt.module.startsWith("gml")) {
			var bts = DocMdAutoTools.toSnakeCase(bt.name);
			return bts.startsWith("ds_") ? bts.substring(3) : bts;
		}
		if (bt.meta.has(":doc")) {
			return DocMdAutoType.printBaseTypeDocName(bt);
		}
		#end
		
		return def;//return bt.name + "@" + bt.module;
	}
}
