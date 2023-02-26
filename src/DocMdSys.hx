package;

import dmd.Misc;
import dmd.WebServer;
import dmd.gml.GmlAPI;
import dmd.gml.HintGML;
import dmd.nodes.DocMdParser;
import haxe.io.Path;
import dmd.misc.StringReader;
import dmd.misc.StringBuilder;
import gml.*;
import sys.FileSystem;
import sys.io.File;
#if neko
import neko.Web;
#end
import tags.*;
using StringTools;
using dmd.MiscTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdSys {
	public static var dir:String;
	public static function expandPath(path:String):String {
		var full = Path.normalize(dir + "/" + path);
		return full.startsWith(dir) ? full : null;
	}
	public static function timeOf(path:String):Float {
		if (FileSystem.exists(path)) {
			return FileSystem.stat(path).mtime.getTime();
		} else return 0;
	}
	public static var lastOutput:String = "";
	public static var lastOutputTime:Float = 0;
	public static var awaitChanges:Array<{path:String,time:Float}> = [];
	public static var includeList:Array<String> = [];
	public static function awaitChangesFor(full:String):Void {
		try {
			awaitChanges.push({path:full, time:timeOf(full)});
		} catch (x:Dynamic) {
			throw "Can't await " + full + ": " + x;
		}
	}
	public static var templateVars:Map<String, String> = new Map();
	public static var argTemplateVars:Map<String, String> = new Map();
	public static var currentDir:String = null;
	public static function procMd(dmd:String, fromDir:String, tplPath:String, to:String){
		currentDir = fromDir;
		// variables:
		var setMap = templateVars;
		setMap.clear();
		for (k => v in argTemplateVars) setMap[k] = v;
		
		//
		if (includeList.length > 0) {
			var b = new StringBuf();
			for (rel in includeList) {
				var path = Misc.resolve(rel);
				if (path != null) {
					b.add(File.getContent(path));
					awaitChangesFor(path);
				}
			}
			b.add(dmd);
			dmd = b.toString();
		}
		
		//
		var html = DocMd.renderExt(dmd, fromDir, setMap);
		if (setMap.exists("template")) {
			tplPath = setMap["template"];
			var _tpl = Misc.resolve(tplPath);
			if (_tpl != null) awaitChangesFor(_tpl);
		}
		//
		if (DocMd.genMode == Linear) {
			if (html.endsWith("<p>")) html = html.substring(0, html.length - 3);
			var pos = html.indexOf("<h2");
			var pos2 = html.indexOf("<hr");
			if ((pos2 >= 0 && pos2 < pos) || pos < 0) pos = pos2;
			if (pos >= 0) {
				var pos0 = pos;
				if (pos >= 5 && html.substring(pos - 5, pos) == "<br/>") pos0 -= 5;
				var pre = html.substring(0, pos);
				// postfix wordpress (`<word` mis-detects as a tag and breaks excerpts):
				pre = ~/(<script.*?>)([\s\S]+?)(<\/script>)/g.map(pre, function(rx:EReg) {
					return rx.matched(1) +
						~/<(\w+)/g.map(rx.matched(2), function(rx2:EReg) {
							 return "< " + rx2.matched(1);
						}) + rx.matched(3);
				});
				//
				html = pre + "\n<!--more-->" + html.substring(pos);
			}
		}
		if (DocMd.genMode == Visual) {
			var coords:Map<String, {x:Float,y:Float,d:Array<String>}> = new Map();
			var navmap:StringBuilder = new StringBuilder();
			navmap.addFormat('```raw\n');
			for (id => s in DocMd.lastSections) {
				var sd = s.split(" ");
				coords[id] = {
					x:Std.parseFloat(sd[0]),
					y:Std.parseFloat(sd[1]),
					d:sd.slice(2),
				};
			}
			var rxt = ~/<h\d>(.+?)<\/h\d>/g;
			for (id => p in coords) {
				var rxi = new EReg('<div id="$id">([\\s\\S]+?)</div>', 'g');
				if (!rxi.match(html)) continue;
				var inner = rxi.matched(1);
				var title = rxt.match(inner) ? rxt.matched(1) : id;
				navmap.addFormat('<a title="%s"', title);
				navmap.addFormat(' href="#%s"', id);
				if (p.d.length > 0) navmap.addFormat(' class="%s"', p.d.join(" "));
				navmap.addFormat(' style="left:%fem;top:%fem">\n', p.x, p.y);
				~/<a href="#(.+?)"/g.each(inner, function(rx:EReg) {
					var ap = coords[rx.matched(1)];
					if (ap == null) return;
					navmap.addFormat('<span class="branch x%fy%f"></span>\n', ap.x - p.x, ap.y - p.y);
				});
				if (!FileSystem.exists(Path.join([Path.directory(to), "nav", id + ".png"]))) id = "unknown";
				navmap.addFormat('<img src="nav/%s.png">\n', id);
				navmap.addFormat('</a>\n');
			}
			navmap.addFormat('```');
			var navstr = navmap.toString();
			setMap.set("navmap", navstr);
		}
		if (DocMd.genMode == Nested) html = "<p>" + html + "</p>";
		
		var out = Misc.getText(tplPath);
		if (out == null) {
			Sys.println("Can't find template `" + tplPath + "`");
			return false;
		}
		
		if (out.indexOf("dmd-linear") >= 0) DocMd.genMode = Linear;
		// fix wrong-case #links
		html = ~/ href="#(\w+)"/g.map(html, function(rx:EReg) {
			var id = rx.matched(1);
			var s = 'id="$id"';
			if (html.indexOf(s) >= 0) return rx.matched(0);
			var r1 = new EReg('id="($id)"', 'i');
			if (r1.match(html)) return ' href="#' + r1.matched(1) + '"';
			if (id.endsWith("s")) {
				id = id.substring(0, id.length - 1);
				r1 = new EReg('id="($id)"', 'i');
				if (r1.match(html)) return ' href="#' + r1.matched(1) + '"';
			}
			return rx.matched(0);
		});
		
		// remove ending <br> tags before paragraph endings:
		html = ~/<br\/>\s*<\/p>/g.replace(html, "</p>");
		
		//
		if (DocMd.genMode == Nested) html = ~/<p>\s*<hr\/>\s*<\/p>/g.replace(html, "<hr/>");
		// remove empty paragraphs:
		html = ~/<p>\s*<\/p>/g.replace(html, "");
		html = ~/(\r?\n[ \t]*)(\r?\n[ \t]*)(<\/p><p>)/g.replace(html, "$1$3$2");
		if (DocMd.genMode == Nested) {
			// fold empty sections:
			html = ~/<section>(<header.*?>.+?<\/header>)<article><\/article><\/section>/g
				.replace(html, '<section class="empty">$1</section>');
			// get rid of empty Uncategorized section in particular:
			html = html.replace('<section class="empty"><header id="uncategorized"><a href="#uncategorized" title="(permalink)">Uncategorized</a></header></section>', '');
		}
		function preproc(html:String, depth:Int = 0):String {
			// <!--%[if 
			html = new EReg("<!--%\\[if\\b\\s*(.+?)\\]-->" + "([\\s\\S]*?)"
				+ "<!--%\\[(?:"
					+ "endif\\]-->"
					+ "|"
					+ "else\\]-->" + "([\\s\\S]*?)" + "<!--%\\[endif\\]-->"
			+ ")(?:\r?\n[ \t]*)?", "g").map(html, function(rx:EReg) {
				var id = rx.matched(1);
				var not = id.charCodeAt(0) == "!".code;
				if (not) id = id.substring(1);
				var ok = not != (setMap.exists(id) && setMap[id] != "");
				if (ok) {
					return rx.matched(2).ltrim();
				} else {
					var otw = rx.matched(3);
					return otw != null ? otw : "";
				}
			});
			// <!--%[var]--> <!--%[var||fallback]-->
			html = ~/<!--%\[(\S+?)(?:\|\|(.*?))?\]-->/g.map(html, function(rx:EReg) {
				var id = rx.matched(1);
				var fb = rx.matched(2);
				if (setMap.exists(id)) {
					return DocMd.render(setMap[id]);
				} else if (fb != null) {
					return fb;
				} else return rx.matched(0);
			});
			html = new EReg("(?:<!--|/\\*)"
				+ "\\[include\\s+(.+?)\\]"
			+ "(?:-->|\\*/)", "g").map(html, function(rx:EReg) {
				var inc = Misc.resolve(rx.matched(1));
				if (inc != null) {
					awaitChangesFor(inc);
					if (depth < 8) {
						return preproc(File.getContent(inc), depth + 1);
					} else {
						Sys.println('Max depth reached while fetching "$inc".');
						return "<!-- max depth reached -->";
					}
				} else return rx.matched(0);
			});
			return html;
		}
		out = preproc(out);
		var s1 = "<!--<doc-->";
		var s2 = "<!--doc>-->";
		var p1 = out.indexOf(s1);
		if (p1 < 0) {
			Sys.println("No opening tag");
			return false;
		}
		p1 += s1.length;
		var p2 = out.lastIndexOf(s2);
		if (p2 < 0) {
			Sys.println("No closing tag");
			return false;
		}
		out = out.substring(0, p1) + html + out.substring(p2);
		lastOutput = out;
		lastOutputTime = Sys.time();
		File.saveContent(to, out);
		return true;
	}
	public static function procPath(from:String, tpl:String, to:String) {
		var dmd:String = File.getContent(from);
		if (dmd == "" && lastOutput != "") return false;
		var fromDir = Path.directory(from);
		return procMd(dmd, fromDir, tpl, to);
	}
	public static function procArgs(args:Array<String>) {
		var extraParamsText:String = null;
		#if macro
		try {
			var extraParamsPath = haxe.macro.Context.resolvePath("dmdExtraParams.txt");
			extraParamsText = File.getContent(extraParamsPath);
		} catch (x:Dynamic) {}
		#else
		try {
			var extraParamsPath = Misc.resolve("dmdExtraParams.txt");
			if (extraParamsPath != null) {
				extraParamsText = File.getContent(extraParamsPath);
			}
		} catch (x:Dynamic) {}
		#end
		if (extraParamsText != null) {
			var lines = extraParamsText.split("\n");
			for (line in lines) {
				line = line.trim();
				if (line == "" || line.startsWith("#")) continue;
				var q = new StringReader(line);
				q.skipLineNonSpaces();
				args.push(q.substring(0, q.pos));
				q.skipLineSpaces();
				while (q.loop) {
					if (q.peek() == '"'.code) {
						q.skip();
						var b = new StringBuilder();
						while (q.loop) {
							var c = q.read();
							if (c == '"'.code) {
								if (q.skipIfEqu('"'.code)) { // ""
									b.addChar('"'.code);
								} else break;
							} else b.addChar(c);
						}
						args.push(b.toString());
					} else {
						var start = q.pos;
						q.skipLineNonSpaces();
						args.push(q.substring(start, q.pos));
					}
					q.skipLineSpaces();
				}
			}
		}
		var i = 0, arg:String;
		var out = { watch: false, server: -1 };
		while (i < args.length) {
			var remove:Int = switch (args[i]) {
				case "--watch": out.watch = true; 1;
				case "--server": out.watch = true; out.server = Std.parseInt(args[i + 1]); 2;
				
				case "--gml-api": GmlAPI.loadEntries(File.getContent(args[i + 1]));  2;
				case "--gml-assets": GmlAPI.loadAssets(File.getContent(args[i + 1])); 2;
				case "--gml-rx-script": HintGML.rxScript = new EReg(args[i + 1], "g"); 2;
				case "--gml-rx-asset": HintGML.rxAsset = new EReg(args[i + 1], "g"); 2;
				
				case "--linear": DocMd.genMode = Linear; 1;
				case "--visual": DocMd.genMode = Visual; 1;
				
				case "--include": includeList.push(args[i + 1]); 2;
				case "--unindent": DocMdParser.trimPlainIndentation = true; 1;
				case "--set", "-D": {
					var pair = args[i + 1];
					var sep = pair.indexOf("=");
					var key:String, val:String;
					if (sep >= 0) {
						key = pair.substring(0, sep);
						val = pair.substring(sep + 1);
					} else {
						key = pair;
						val = "";
					}
					argTemplateVars[key] = val;
					2;
				};
				default: 0;
			}
			if (remove > 0) args.splice(i, remove); else i++;
		}
		return out;
	}
	static function main() {
		var args = Sys.args();
		var watch = false;
		//
		var argsOut = procArgs(args);
		var watch = argsOut.watch;
		var server = argsOut.server;
		if (args.length > 0 && Path.extension(args[0]).toLowerCase() == "html") {
			Sys.println("First argument should not be a HTML document.");
			return;
		}
		if (args.length == 1) {
			var arg1 = args[0];
			if (Path.extension(arg1) == "") arg1 += ".dmd";
			var arg2 = arg1 + ".html";
			var arg3 = Path.withoutExtension(arg1) + ".html";
			if (FileSystem.exists(arg2)) {
				args.push(arg2);
				args.push(arg3);
			} else if (FileSystem.exists(arg3)) {
				args.push(arg3);
			}
		}
		if (args.length < 2) {
			Sys.println("Use: ");
			Sys.println("docmd [doc.dmd] (modifies doc.html)");
			Sys.println("docmd [doc.dmd] [to.html] (modifies to.html)");
			Sys.println("docmd [doc.dmd] [template.dmd.html] [to.html] (rewrites s to.html)");
			Sys.println("Optionals:");
			Sys.println("--watch: Watch for file changes");
			Sys.println("--api [path]: Load API from non-standard fnames");
			Sys.println("--assets [path]: Load asset list");
			return;
		}
		var from = args[0];
		var tpl = args[1];
		var to = args[2];
		if (tpl == null) {
			var nx = Path.withoutExtension(from);
			tpl = nx + ".dmd.html";
			to = nx + ".html";
		} else if (to == null) to = tpl;
		dir = Path.directory(from);
		if (dir == "") dir = Sys.getCwd();
		dir = Path.normalize(dir);
		var time = 0.;
		var time_tpl = 0.;
		if (!watch) {
			DocMd.reset();
			procPath(from, tpl, to);
			return;
		}
		if (server != -1) {
			sys.thread.Thread.create(function() {
				dmd.WebServer.start(server);
			});
		}
		while (true) {
			Sys.sleep(0.5);
			var t = timeOf(from);
			var t2 = tpl != to ? timeOf(tpl) : 0.;
			var tz = false;
			for (pair in awaitChanges) {
				if (timeOf(pair.path) > pair.time) {
					tz = true; break;
				}
			}
			if (time != t && FileSystem.stat(from).size > 0 || time_tpl != t2 || tz) {
				time = t; time_tpl = t2;
				awaitChanges.resize(0);
				Sys.print("[" + Date.now().toString() + "] Rendering... ");
				try {
					DocMd.reset();
					procPath(from, tpl, to);
					Sys.println("OK!");
				} catch (e:Dynamic) {
					Sys.println("error!");
					Sys.println("" + e);
					Sys.println(haxe.CallStack.exceptionStack().join("\n"));
				}
			}
		}
	}
	
}
