package dmd.auto;
import dmd.auto.DocMdAutoEl;
import dmd.auto.DocMdAutoExtract;
import haxe.macro.Type;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdAutoResolver {
	public static function resolveType(path:String, relPack:Array<String>):ModuleType {
		var mt = DocMdAuto.fqMap[path];
		if (mt != null) return mt;
		if (path.indexOf(".") < 0 && relPack != null) {
			var packLen = relPack.length + 1;
			while (--packLen >= 0) {
				var pkgb = new StringBuf();
				for (k in 0 ... packLen) {
					if (k > 0) pkgb.add(".");
					pkgb.add(relPack[k]);
				}
				var pkgi = pkgb.toString();
				var mts = DocMdAuto.packageMap[pkgi];
				if (mts == null) continue;
				var mt = mts[path];
				if (mt != null) return mt;
			}
		}
		return null;
	}
	public static function resolveField(mt:ModuleType, id:String, full:Bool):DocMdAutoResolverPair {
		if (mt != null) switch (mt) {
			case TClassDecl(_.get() => ct): {
				var isStruct = DocMdAutoExtract.metaStruct(ct.meta);
				var statics = ct.statics.get();
				for (fd in statics) if (fd.name == id) {
					return {
						name: DocMdAutoType.printFieldPath(fd.name, StaticVar, fd.meta, ct),
						id: DocMdAutoType.printFieldPath(fd.name, Flat, fd.meta, ct),
					};
				}
				var fields = ct.fields.get();
				for (fd in fields) if (fd.name == id) {
					var name:String;
					if (!full && DocMdAutoExtract.metaStruct(ct.meta)) {
						name = fd.name;
					} else name = DocMdAutoType.printFieldPath(fd.name, InstVarFQ, fd.meta, ct);
					return {
						name: name,
						id: DocMdAutoType.printFieldPath(fd.name, Flat, fd.meta, ct),
					};
				}
				if ((id == "new" || id == "create") && ct.constructor != null)  {
					var ctr = ct.constructor.get();
					return {
						name: DocMdAutoType.printFieldPath(ctr.name, Constructor, ctr.meta, ct),
						id: DocMdAutoType.printFieldPath(ctr.name, Flat, ctr.meta, ct),
					};
				}
			};
			case TEnumDecl(_.get() => et): {
				var ctr = et.constructs[id];
				if (ctr != null) return {
					name: DocMdAutoType.printFieldPath(ctr.name, EnumCtr, ctr.meta, et),
					id: DocMdAutoType.printFieldPath(ctr.name, Flat, ctr.meta, et),
				};
			};
			default:
		}
		return null;
	}
	public static function mapOne(id:String, emt:ModuleType):DocMdAutoResolverPair {
		if (DocMdAuto.sectionMap[id] != null) return null;
		//
		var fds = resolveField(emt, id, false);
		if (fds != null) return fds;
		//
		var bt = DocMdAutoType.baseTypeForModuleType(emt);
		if (bt != null) {
			var mt = resolveType(id, bt.pack);
			if (mt != null) {
				var mtp = DocMdAutoType.printModuleTypePath(mt);
				return { name: mtp, id: mtp };
			}
		}
		//
		return null;
	}
	public static function mapTwo(at:String, fd:String, emt:ModuleType):DocMdAutoResolverPair {
		var bt = DocMdAutoType.baseTypeForModuleType(emt);
		var mt = resolveType(at, bt != null ? bt.pack : null);
		if (mt != null) {
			return resolveField(mt, fd, true);
		} else { // well OK, might be a FQ type path
			var mt = DocMdAuto.fqMap[at + "." + fd];
			if (mt != null) {
				var mtp = DocMdAutoType.printModuleTypePath(mt);
				return { name: mtp, id: mtp };
			} else return null;
		}
	}
	public static function proc(text:String, emt:ModuleType):String {
		//
		text = ~/\[([A-Za-z_]\w*)\]/g.map(text, function(rx:EReg) {
			var pp = rx.matchedPos();
			if (text.fastCodeAt(pp.pos + pp.len) == "(".code) return rx.matched(0);
			var p = mapOne(rx.matched(1), emt);
			if (p == null) return rx.matched(0);
			if (p.name == p.id) return '[${p.name}]';
			return '[${p.name}](${p.id})';
		});
		text = ~/\]\(([A-Za-z_]\w*)\)/g.map(text, function(rx:EReg) {
			var p = mapOne(rx.matched(1), emt);
			if (p == null) return rx.matched(0);
			return '](${p.id})';
		});
		//
		text = ~/\[([A-Za-z_][\w.]*?)\.(\w+)\]/g.map(text, function(rx:EReg) {
			var pp = rx.matchedPos();
			if (text.fastCodeAt(pp.pos + pp.len) == "(".code) return rx.matched(0);
			var p = mapTwo(rx.matched(1), rx.matched(2), emt);
			if (p == null) return rx.matched(0);
			if (p.name == p.id) return '[${p.name}]';
			return '[${p.name}](${p.id})';
		});
		text = ~/\]\(([A-Za-z_][\w.]*?)\.(\w+)\)/g.map(text, function(rx:EReg) {
			var p = mapTwo(rx.matched(1), rx.matched(2), emt);
			if (p == null) return rx.matched(0);
			return '](${p.id})';
		});
		//
		return text;
	}
	public static function seekRec(el:DocMdAutoEl) {
		for (ch in el.children) seekRec(ch);
		//
		var text = el.text;
		if (text != null && text != "") {
			el.text = proc(text, el.moduleType);
		}
	}
}
typedef DocMdAutoResolverPair = { name:String, id:String };
