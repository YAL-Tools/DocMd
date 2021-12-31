package;
import haxe.Json;
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.PositionTools;
import haxe.macro.Type;
import haxe.macro.Expr;
import dmd.misc.StringBuilder;
import sys.io.File;
import dmd.auto.*;
import dmd.auto.DocMdAutoFieldKind;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdAuto {
	public static var fqMap:Map<String, ModuleType>;
	public static var packageMap:Map<String, Map<String, ModuleType>>;
	public static var sectionMap:Map<String, DocMdAutoSection>;
	
	static function or<T>(a:T, b:T):T {
		return a != null ? a : b;
	}
	static function cct(a:String, b:String):String {
		if (a == null || a.trim() == "") return b;
		if (b == null || b.trim() == "") return a;
		return a + "\n" + b;
	}
	
	static var rxReturn = ~/\n\s*@return\s+(.+)/;
	static var rxDocStart = ~/^\s*\* /gm;
	static function procType(mt:ModuleType) {
		var tdoc:Bool, bt:BaseType, ct:ClassType = null;
		var tpar:DocMdAutoSection, tparOrig:DocMdAutoSection;
		var btNative:String = null, btSnakeCase:Bool, btStruct:Bool, btOrder:Null<Float>;
		var thisName:String = null;
		function prepare(_bt:BaseType) {
			bt = _bt;
			tdoc = bt.meta.has(":doc");
			btSnakeCase = DocMdAutoExtract.metaSnake(bt.meta);
			btStruct = DocMdAutoExtract.metaStruct(bt.meta);
			btOrder = DocMdAutoExtract.metaFloat(bt.meta, ":dmdOrder");
			var tp = DocMdAutoExtract.dmdPath(bt.meta, mt);
			var rbtd = bt.doc != null ? [
				DocMdAutoExtract.docPreproc(rxDocStart.replace(bt.doc, ""), bt)
			] : null;
			if (tp == null && rbtd != null) {
				tp = DocMdAutoExtract.docPath(rbtd, "@dmdPath");
			}
			if (tp != null) {
				var tpl = tp.length;
				if (tpl > 0 && Std.is(tp[tpl - 1], Array) && tp[tpl - 1][0] == "") {
					tp[tpl - 1][0] = DocMdAutoType.printBaseTypePath(bt);
				}
				tpar = DocMdAutoBuilder.find(tp, bt.pos);
				
				//
				if (tpar.moduleType == null) tpar.moduleType = mt;
				
				//
				tpar.prefix = cct(tpar.prefix, DocMdAutoExtract.docMeta(rbtd, "@dmdPrefix"));
				tpar.suffix = cct(tpar.suffix, DocMdAutoExtract.docMeta(rbtd, "@dmdPrefix"));
				
				//
				if (rbtd != null) {
					DocMdAutoExtract.docMeta(rbtd, "@author");
					btOrder = or(DocMdAutoExtract.docFloat(rbtd, "@dmdOrder"), btOrder);
					tpar.text = cct(tpar.text, rbtd[0]);
				}
			} else tpar = null;
			tparOrig = tpar;
			return (bt.isExtern || bt.meta.has(":std")) && !tdoc;
		}
		function isDoc(meta:MetaAccess) {
			return !meta.has(":noDoc") && (tdoc || meta.has(":doc") || meta.has(":expose"));
		}
		function add(id:String, title:String, meta:MetaAccess, doc:String, pos:Position) {
			var fch = DocMdAutoExtract.dmdPath(meta, mt);
			var rd = [doc != null ?
				DocMdAutoExtract.docPreproc(rxDocStart.replace(doc, ""), bt)
			: null];
			if (DocMdAutoExtract.docMeta(rd, "@dmdResetPath") != null) {
				tpar = tparOrig;
			}
			if (fch == null) fch = DocMdAutoExtract.docPath(rd, "@dmdPath");
			if (fch == null) {
				fch = DocMdAutoExtract.docPath(rd, "@dmdSetPath");
				if (fch == null) fch = DocMdAutoExtract.dmdSetPath(meta);
				if (fch != null) tpar = DocMdAutoBuilder.find(fch, pos);
			}
			var fpar;
			if (fch != null) {
				fpar = DocMdAutoBuilder.find(fch, pos);
			} else {
				if (tpar == null) tpar = DocMdAutoBuilder.find(DocMdAutoExtract.dmdPath(bt.meta, mt), bt.pos);
				fpar = tpar;
			}
			var sct = new DocMdAutoSection(id, mt);
			sectionMap[id] = sct;
			//
			var docOrder = DocMdAutoExtract.docMeta(rd, "@dmdOrder"), order:Null<Float>;
			if (docOrder != null) {
				order = Std.parseFloat(docOrder);
			} else if ((docOrder = DocMdAutoExtract.docMeta(rd, "@dmdSetOrder")) != null) {
				btOrder = order = Std.parseFloat(docOrder);
			} else {
				order = DocMdAutoExtract.metaFloat(meta, ":dmdOrder");
				if (order == null) {
					order = DocMdAutoExtract.metaFloat(meta, ":dmdSetOrder");
					if (order != null) {
						btOrder = order;
					} else order = btOrder;
				}
			}
			if (order != null) sct.order = order;
			//
			sct.prefix = or(DocMdAutoExtract.docMeta(rd, "@dmdPrefix"), DocMdAutoExtract.metaString(meta, ":dmdPrefix"));
			sct.suffix = or(DocMdAutoExtract.docMeta(rd, "@dmdSuffix"), DocMdAutoExtract.metaString(meta, ":dmdSuffix"));
			sct.title = title;
			sct.text = or(DocMdAutoExtract.metaString(meta, ":dmdText"), rd[0]);
			//
			fpar.addSection(sct);
			return sct;
		}
		function addField(name:String, type:Type, meta:MetaAccess, doc:String, pos:Position, kind:DocMdAutoFieldKind) {
			if (!isDoc(meta)) return;
			if (btNative == null) btNative = DocMdAutoType.printBaseTypePath(bt);
			var id = DocMdAutoType.printFieldPath(name, Flat, meta, bt, btNative);
			var title = btStruct ? DocMdAutoType.printFieldPath(name, kind, meta, bt, btNative) : id;
			var rfd = [doc];
			switch (type) {
				case TFun(args, rt): {
					var tb = new StringBuf();
					tb.add(title);
					if (kind == InstVar) {
						if (!btStruct) {
							tb.add(":index:script");
						} else tb.add(":script");
					} else if (kind == StaticVar) tb.add(":script");
					tb.add("(");
					var sep = false;
					if (kind == InstFunc && !btStruct) {
						sep = true;
						tb.add(thisName);
					}
					for (arg in args) {
						if (sep) tb.add(", "); else sep = true;
						if (arg.opt) tb.add("?");
						var btp = DocMdAutoType.baseTypeForType(arg.t);
						if (btp != null) {
							var docArgText = DocMdAutoExtract.metaString(btp.baseType.meta, ":docArgText");
							if (docArgText != null) {
								tb.add(docArgText);
								continue;
							}
						}
						var an = arg.name;
						if (an == null || an == "") {
							tb.add("\\_");
						} else tb.add(an);
					}
					tb.add(")");
					var rtd = DocMdAutoExtract.docMeta(rfd, "@return");
					if (kind == Constructor && btStruct) {
						// it has `new`, you get it
					} else if (rtd != null) {
						tb.add("->");
						tb.add(rtd);
					} else {
						rtd = DocMdAutoType.print(rt);
						if (rtd != "void") {
							tb.add("->");
							if (rtd != null) {
								tb.add(rtd);
							} else {
								//tb.add(DocMdAutoType.printBaseTypeDocName(bt));
							}
						}
					}
					title = tb.toString();
				};
				case TEnum(t, _) if (kind == EnumCtr): {};
				default: {
					var rtd = DocMdAutoExtract.docMeta(rfd, "@type");
					if (kind == InstVar && !btStruct) title += ":index";
					if (rtd != null) {
						if (rtd.startsWith("(")) {
							#if gml
							rtd = "script" + rtd;
							#else
							rtd = "function" + rtd;
							#end
						}
						title += ":" + rtd;
					} else {
						rtd = DocMdAutoType.print(type);
						if (rtd != null) title += ":" + rtd;
					}
				};
			}
			add(id, title, meta, rfd[0], pos);
		}
		switch (mt) {
			case TClassDecl(_ct): {
				ct = _ct.get();
				if (prepare(ct)) return;
				function procClassField(fd:ClassField, isStatic:Bool) {
					var kind = switch (fd.kind) {
						case FMethod(_): isStatic ? StaticFunc : InstFunc;
						default: isStatic ? StaticVar : InstVar;
					}
					addField(fd.name, fd.type, fd.meta, fd.doc, fd.pos, kind);
				}
				for (fd in ct.statics.get()) procClassField(fd, true);
				if (ct.constructor != null) {
					var fd = ct.constructor.get();
					var ctrType = fd.type;
					switch (ctrType) {
						case TFun(args, _): ctrType = TFun(args, TInst(_ct, []));
						default:
					}
					if (btNative == null) btNative = DocMdAutoType.printBaseTypePath(bt);
					var ctrName = btStruct ? "new " + btNative : "create";
					addField(ctrName, ctrType, fd.meta, fd.doc, fd.pos, Constructor);
				}
				//
				var instFields = ct.fields.get();
				if (instFields.length > 0) {
					thisName = DocMdAutoType.printBaseTypeDocName(bt);
					for (fd in instFields) procClassField(fd, false);
				}
			};
			case TEnumDecl(_.get() => et): {
				if (prepare(et)) return;
				var ecs = [];
				for (k => ec in et.constructs) {
					ecs.push({
						ctr: ec,
						ofs: PositionTools.getInfos(ec.pos).min
					});
				}
				ecs.sort(function(ep1, ep2) { return ep1.ofs - ep2.ofs; });
				for (ep in ecs) {
					var ec = ep.ctr;
					addField(ec.name, ec.type, ec.meta, ec.doc, ec.pos, EnumCtr);
				}
			};
			default:
		}
	}
	
	static var dmdFullPath:String;
	static function onAfterTyping(types:Array<ModuleType>, path:String, out:StringBuf) {
		var dmdPath = path;
		if (Path.extension(dmdPath) == "") dmdPath += ".dmd";
		if (!Path.isAbsolute(dmdPath)) dmdPath = Context.resolvePath(dmdPath);
		dmdFullPath = dmdPath;
		var template = File.getContent(dmdPath);
		var gml_variant = -1;
		#if (sfgml)
			#if (sfgml.modern && !sfgml_linear)
				#if sfgml_snake_case
				gml_variant = 1;
				#else
				gml_variant = 2;
				#end
			#else
				gml_variant = 0;
			#end
		#end
		if (gml_variant >= 0) {
			template = '```set gml_variant $gml_variant```\r\n'
				#if hscript
				+ '```exec'
				+ ' gml_variant = $gml_variant;'
				+ ' gml_modern = ${gml_variant > 0};'
				+ ' gml_oo = ${gml_variant > 1};'
				+ ' return;```\r\n'
				#end
				+ template;
		}
		//
		DocMdAutoBuilder.autoOrder = new Map();
		var rxOrder = ~/```set\s+dmdOrder\b([\s\S]+?)```/;
		if (rxOrder.match(template)) {
			var ind = 0;
			~/(\b[a-zA-Z][\w-]*)(?::(\d+))?/g.map(rxOrder.matched(1), function(rx:EReg):String {
				var id = rx.matched(1);
				DocMdAutoBuilder.autoOrder[id] = ++ind;
				return rx.matched(0);
			});
		}
		//
		fqMap = new Map();
		packageMap = new Map();
		sectionMap = new Map();
		for (type in types) {
			var bt:BaseType = DocMdAutoType.baseTypeForModuleType(type);
			if (bt == null) continue;
			var fqb = new StringBuf();
			var btp = bt.pack;
			for (el in btp) fqb.add(el + ".");
			var name = bt.name;
			fqb.add(name);
			var fqs = fqb.toString();
			fqMap[fqs] = type;
			//
			var pkg = btp.join(".");
			var mts = packageMap[pkg];
			if (mts == null) {
				mts = new Map();
				packageMap[pkg] = mts;
			}
			mts[bt.name] = type;
		}
		//
		DocMdAutoBuilder.root = new DocMdAutoSection(null, null);
		for (type in types) procType(type);
		DocMdAutoResolver.seekRec(DocMdAutoBuilder.root);
		//
		template = DocMdAutoResolver.proc(template, null);
		var p1 = template.indexOf("%[autogen]"), p2:Int;
		if (p1 < 0) {
			p1 = template.length;
			p2 = p1;
		} else p2 = p1 + "%[autogen]".length;
		out.add(template.substring(0, p1));
		DocMdAutoBuilder.root.sortRec();
		DocMdAutoBuilder.root.print(out);
		out.add(template.substring(p2));
		//File.saveContent("temp.dmd", out.toString());
	}
	static function onAfterGenerate(path:String, outPath:String, out:StringBuf) {
		if (outPath == null) {
			outPath = Path.withExtension(dmdFullPath, "html");
		} else if (Path.extension(outPath) == "") {
			outPath += ".html";
		}
		DocMdSys.procMd(out.toString(), Path.directory(path), outPath, outPath);
	}
	public static function proc(path:String, ?outPath:String) {
		#if !display
		var out = new StringBuf();
		Context.onAfterTyping(function(types) {
			onAfterTyping(types, path, out);
		});
		Context.onAfterGenerate(function() {
			onAfterGenerate(path, outPath, out);
		});
		#end
	}
}
