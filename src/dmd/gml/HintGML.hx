package dmd.gml;
import dmd.gml.GmlAPI;
import dmd.misc.*;
import haxe.ds.Map;
import dmd.misc.StringBuilder;
import dmd.misc.StringReader;
import dmd.gml.GmlAPI;
import dmd.gml.HintGML.GmlToken.*;

/**
 * ...
 * @author YellowAfterlife
 */
class HintGML {
	public static var rxScript = ~/^scr[_A-Z]/g;
	public static var rxAsset = ~/^(?:obj|spr|bck|rm|fnt|snd|tl)[_A-Z]/g;
	public static var version:Int = 1;
	public static var liveExt:Bool = false;
	static var mode:GMLMode = GML;
	static inline var bss = 92; // backslash
	static function parseSub(q:StringReader, tokens:Array<GmlToken>, tplStart:Int):Void {
		var isGML = mode == GML;
		var isLua = mode == Lua;
		var isAHK = mode == AHK;
		var keywords = isAHK ? AHKAPI.keywords : (isLua ? LuaAPI.keywords : GmlAPI.keywords);
		var builtin = isLua || isAHK ? new Map() : GmlAPI.builtin;
		var start:Int, c:Int, c1:Int;
		var i:Int, s:String;
		inline function add(tk:GmlToken):Void {
			tokens.push(tk);
		}
		inline function addOp():Void {
			tokens.push(Op(q.substring(start, q.pos)));
		}
		inline function isIdent0(c:Int) {
			return c >= "a".code && c <= "z".code
				|| c >= "A".code && c <= "Z".code
				|| c == "_".code;
		}
		inline function isIdent1(c:Int) {
			return c >= "a".code && c <= "z".code
				|| c >= "A".code && c <= "Z".code
				|| c >= "0".code && c <= "9".code
				|| c == "_".code;
		}
		inline function skipSpace():Void {
			while (q.loop) {
				switch (q.peek()) {
					case " ".code, "\t".code, "\r".code, "\n".code: {
						q.skip(); continue;
					};
					default: { }; // ->
				}; break;
			}
		}
		/** changes `c` */
		inline function skipIdent():Void {
			while (q.loop) {
				c = q.peek();
				if (isIdent1(c)) {
					q.skip();
				} else break;
			}
		}
		//
		var cubDepth:Int = 0;
		var v = version;
		var lx = liveExt;
		while (q.loop) {
			start = q.pos;
			c = q.read();
			switch (c) {
				case " ".code, "\t".code, "\r".code, "\n".code: {
					while (q.loop) {
						switch (q.peek()) {
							case " ".code, "\t".code, "\r".code, "\n".code: {
								q.pos += 1;
								continue;
							};
							default: // ->
						}; break;
					}
					add(Spaces(q.substring(start, q.pos)));
				};
				case "#".code: { // #define #macro #
					while (q.loop) {
						c = q.peek();
						if (c >= "a".code && c <= "z".code
							|| isAHK && c >= "A".code && c <= "Z".code
						) {
							q.skip();
						} else break;
					}
					s = q.substring(start, q.pos);
					if (isAHK) {
						add(Meta(s));
					} else switch (s) {
						case "#define": add(Define);
						case "#macro": add(Macro);
						case "#region", "#endregion": {
							add(Meta(s));
							start = q.pos;
							while (q.loop) {
								switch (q.peek()) {
									case "\r".code, "\n".code: { }; // ->
									default: q.skip(); continue;
								}; break;
							}
							add(Comment(q.substring(start, q.pos)));
						};
						default: q.pos = start + 1; add(Op("#"));
					}
				};
				case ";".code if (isAHK): {
					q.skip();
					while (q.loop) {
						switch (q.peek()) {
							case "\r".code, "\n".code: { }; // ->
							default: q.skip(); continue;
						}; break;
					}
					add(Comment(q.substring(start, q.pos)));
				};
				case "?".code, ":".code, "~".code, ";".code, ",".code: {
					addOp();
				};
				case "-".code: {
					c1 = q.peek();
					switch (c1) {
						case "=".code: {
							q.skip();
							addOp();
						};
						case "-".code: {
							if (isLua) {
								q.skip();
								while (q.loop) {
									switch (q.peek()) {
										case "\r".code, "\n".code: { }; // ->
										default: q.skip(); continue;
									}; break;
								}
								add(Comment(q.substring(start, q.pos)));
							} else {
								q.skip();
								addOp();
							}
						};
						default: addOp();
					}
				};
				case "+".code, "&".code, "|".code, "^".code, ">".code: {
					c1 = q.peek();
					if (c1 == "=".code || c1 == c) q.skip();
					addOp();
				};
				case "*".code, "%".code, "=".code, "!".code: {
					if (q.peek() == "=".code) q.skip();
					addOp();
				};
				case "<".code: {
					switch (q.peek()) {
						case "<".code, ">".code, "=".code: q.skip();
					}
					addOp();
				};
				case "/".code: switch (q.peek()) {
					case "/".code if (isGML): {
						q.skip();
						while (q.loop) {
							switch (q.peek()) {
								case "\r".code, "\n".code: { }; // ->
								default: q.skip(); continue;
							}; break;
						}
						add(Comment(q.substring(start, q.pos)));
					};
					case "*".code if (isGML): {
						q.skip();
						while (q.loop) {
							if (q.peek() == "*".code) {
								q.skip();
								if (q.peek() == "/".code) {
									q.skip();
									break;
								}
							} else q.skip();
						}
						add(Comment(q.substring(start, q.pos)));
					};
					case "=".code: q.skip(); addOp();
					default: addOp();
				};
				case "(".code: add(ParOpen);
				case ")".code: add(ParClose);
				case "[".code: add(SqbOpen);
				case "]".code: add(SqbClose);
				case "{".code: {
					cubDepth += 1;
					add(CubOpen);
				};
				case "}".code: {
					if (--cubDepth <= 0 && tplStart >= 0) {
						q.pos -= 1;
						return;
					} else add(CubClose);
				};
				case "@".code: {
					if (v >= 2) switch (q.peek()) {
						case '"'.code: {
							q.skip();
							while (q.loop) {
								c = q.read();
								if (c == '"'.code) break;
							}
							add(CString(q.substring(start, q.pos)));
						};
						case "'".code: {
							q.skip();
							while (q.loop) {
								c = q.read();
								if (c == "'".code) break;
							}
							add(CString(q.substring(start, q.pos)));
						};
						default: addOp();
					} else addOp();
				};
				case "'".code: {
					while (q.loop) {
						c = q.read();
						if (c == "'".code) break;
					}
					add(CString(q.substring(start, q.pos)));
				};
				case '"'.code: {
					if (v >= 2) {
						while (q.loop) {
							c = q.read();
							if (c == '"'.code) break;
							if (c == bss) switch (c) {
								case "u".code: q.pos += 5;
								case "x".code: q.pos += 3;
								default: q.pos += 1;
							}
						}
					} else {
						while (q.loop) {
							c = q.read();
							if (c == '"'.code) break;
						}
					}
					add(CString(q.substring(start, q.pos)));
				};
				case "`".code: if (lx) {
					c1 = q.peek();
					while (c1 != "`".code && q.loop) {
						q.skip();
						if (c1 == "$".code) {
							c1 = q.peek();
							if (c1 == "{".code) {
								q.skip();
								add(TString(q.substring(start, q.pos)));
								parseSub(q, tokens, q.pos);
								start = q.pos;
							}
						}
						c1 = q.peek();
					}
					if (q.loop) q.skip();
					add(TString(q.substring(start, q.pos)));
				} else add(Spaces("`"));
				case ".".code: {
					add(Op("."));
					start = q.pos;
					skipSpace();
					if (q.pos > start) add(Spaces(q.substring(start, q.pos)));
					c = q.peek();
					if (isIdent0(c)) {
						skipIdent();
						add(Field(q.substring(start, q.pos)));
					}
				};
				default: {
					if(c >= "a".code && c <= "z".code
					|| c >= "A".code && c <= "Z".code
					|| c == "_".code) {
						skipIdent();
						s = q.substring(start, q.pos);
						if (s == "global") {
							add(Keyword(s));
							start = q.pos;
							skipSpace();
							if (q.pos > start) add(Spaces(q.substring(start, q.pos)));
							if (q.peek() == ".".code) {
								add(Op("."));
								q.skip();
								//
								start = q.pos;
								skipSpace();
								if (q.pos > start) add(Spaces(q.substring(start, q.pos)));
								//
								start = q.pos;
								skipIdent();
								if (q.pos > start) add(Global(q.substring(start, q.pos)));
							}
						} else if (keywords.exists(s) || isAHK && keywords.exists(s.toLowerCase())) {
							add(Keyword(s));
						} else {
							i = q.pos;
							while (i < q.length) {
								switch (q.get(i)) {
									case " ".code, "\t".code, "\r".code, "\n".code: {
										i += 1; continue;
									};
									default: { }; // ->
								}; break;
							}
							if (q.get(i) == "(".code) {
								add(builtin.exists(s) ? Func(s) : Script(s));
							} else if (builtin.exists(s)) {
								add(Builtin(s));
							} else if (GmlAPI.assets.exists(s)) {
								add(Asset(s));
							} else if (start > 0 && q.get(start - 1) != ".".code) {
								if (rxScript.match(s)) {
									add(Script(s));
								} else if (rxAsset.match(s)) {
									add(Asset(s));
								} else add(Ident(s));
							} else add(Ident(s));
						}
					}
					else if (c >= "0".code && c <= "9".code || c == ".".code || c == "$".code) {
						var kind = 0;
						switch (c) {
							case "0".code: {
								if (q.get(q.pos) == "x".code) {
									q.pos += 1;
									kind = 1;
								}
							};
							case "$".code: kind = 1;
							case ".".code: {
								c1 = q.get(q.pos);
								if (c1 < "0".code || c1 > "9".code) kind = -1;
							}
						}
						switch (kind) {
							case -1: add(Op("."));
							case 1: {
								while (q.loop) {
									c = q.peek();
									if(c >= "0".code && c <= "9".code
									|| c >= "A".code && c <= "F".code
									|| c >= "a".code && c <= "f".code) {
										q.pos += 1;
									} else break;
								}
								add(Number(q.substring(start, q.pos)));
							};
							default: {
								while (q.loop) {
									c = q.peek();
									if (c == ".".code || c >= "0".code && c <= "9".code) {
										q.pos += 1;
									} else break;
								}
								add(Number(q.substring(start, q.pos)));
							};
						}
					}
					else add(Spaces(String.fromCharCode(c)));
				};
			}
		}
	}
	public static function parse(code:String):Array<GmlToken> {
		var reader = new StringReader(code);
		var tokens:Array<GmlToken> = [];
		parseSub(reader, tokens, -1);
		return tokens;
	}
	static function parseLocals(
		locals:Map<String, Bool>, tokens:Array<GmlToken>, start:Int, end:Int
	) {
		var pos = start;
		while (pos < end) {
			switch (tokens[pos++]) {
				case Keyword("var"), Keyword("local"), Keyword("static"): {};
				case Keyword("catch"): {
					if (pos < end && tokens[pos].match(Spaces(_))) pos++;
					if (pos < end && tokens[pos].match(ParOpen)) pos++;
					if (pos < end && tokens[pos].match(Spaces(_))) pos++;
					if (pos < end) switch (tokens[pos++]) {
						case Ident(v): locals.set(v, true);
						default: {};
					}
					continue;
				};
				default: continue;
			}
			var depth = -1, loop = true;
			while (loop && pos < end) switch (tokens[pos++]) {
				case Ident(s): {
					if (depth < 0) locals.set(s, true);
					while (pos < end) {
						switch (tokens[pos++]) {
							case Spaces(_): continue;
							case Comment(_): continue;
							case Op(":"): {
								switch (tokens[pos]) {
									case Ident(t): {
										tokens[pos] = Func(t);
										pos++;
									};
									default:
								}
							};
							case Op("="): depth++;
							case Op(","): { };
							default: loop = false;
						}; break;
					}
				};
				case ParOpen, SqbOpen: depth++;
				case ParClose, SqbClose: depth--;
				case Op(","): if (depth == 0) depth--;
				case Op(";"): loop = false;
				default: continue;
			}
		}
	}
	static function hintLocals(tokens:Array<GmlToken>, scopes:Map<String, Map<String, Bool>>) {
		var length = tokens.length;
		var scripts = new Map<String, Bool>();
		for (pos in 0 ... length) {
			if (tokens[pos].match(Define|Macro)) switch (tokens[pos + 2]) {
				case Ident(s): scripts.set(s, true);
				default:
			}
		}
		//
		var start = 0;
		var scope = "";
		var end = -1;
		var cubDepth = 0;
		while (++end <= length) {
			//
			if (end >= length) {
				// OK!
			} else switch (tokens[end]) {
				case CubOpen: cubDepth++; continue;
				case CubClose: cubDepth--; continue;
				case Define: {};
				case Keyword("function"): if (cubDepth == 0) continue;
				default: continue;
			}
			
			//
			var locals = scopes != null ? scopes[scope] : null;
			if (locals == null) locals = new Map<String, Bool>();
			
			// a space? what for
			var pos = start;
			if (pos < end && tokens[pos].match(Spaces(_))) pos += 1;
			
			//
			if (pos + 3 < end
				&& tokens[pos].match(Define)
				&& tokens[pos + 3].match(ParOpen)
			) { // +0:"#define", +1:" ", +2:"func", +3:"("
				pos += 3;
				while (pos < end) switch (tokens[pos++]) {
					case Ident(s): locals.set(s, true);
					case ParClose: break;
					default:
				}
			}
			
			//
			parseLocals(locals, tokens, pos, end);
			
			//
			var pos = start - 1;
			while (++pos < end) switch (tokens[pos]) {
				case Keyword("function"): {
					var fp = pos + 1;
					var namePos = -1;
					if (fp < length && tokens[fp].match(Spaces(_))) fp++;
					if (fp < length) switch (tokens[fp]) {
						case Ident(s): {
							tokens[fp] = Script(s);
							fp++;
						};
						default:
					}
					while (fp < end) switch (tokens[fp++]) {
						case Ident(s): locals.set(s, true);
						case ParClose: break;
						default:
					}
				};
				case Ident(s): {
					if (locals.exists(s)) {
						tokens[pos] = Local(s);
					} else if (scripts.exists(s)) {
						tokens[pos] = Script(s);
					}
				};
				default:
			}
			//
			if (end + 2 < length) switch (tokens[end + 2]) {
				case Ident(s): scope = s;
				default:
			}
			//
			start = end;
		}
	}
	public static function print(tokens:Array<GmlToken>, cname:String):String {
		var q = new StringBuilder();
		if (cname != null) q.addString('<pre class="$cname">');
		inline function plain(s:String):String {
			return StringTools.htmlEscape(s);
		}
		inline function cl(c:String, s:String) {
			q.addString('<span class="$c">');
			q.addString(plain(s));
			q.addString('</span>');
		}
		for (tk in tokens) switch (tk) {
			case Spaces(s): q.addString(s);
			case Define: cl("md", "#define");
			case Macro: cl("md", "#macro");
			case Meta(s): cl("md", s);
			case Comment(s): cl("co", s);
			case Op(s): cl("op", s);
			case Number(s): cl("nu", s);
			case CString(s): cl("st", s);
			case TString(s): cl("ts", s);
			case ParOpen: cl("op", "(");
			case ParClose: cl("op", ")");
			case SqbOpen: cl("op", "[");
			case SqbClose: cl("op", "]");
			case CubOpen: cl("cb", "{");
			case CubClose: cl("cb", "}");
			case Func(s): cl("sf", s);
			case Builtin(s): cl("sv", s);
			case Keyword(s): cl("kw", s);
			case Ident(s): cl("uv", s);
			case Field(s): cl("fd", s);
			case Global(s): cl("gv", s);
			case Script(s): cl("uf", s);
			case Asset(s): cl("ri", s);
			case Local(s): cl("lv", s);
			default: q.addString(plain(Std.string(tk)));
		}
		if (cname != null) q.addString('</pre>');
		return q.toString();
	}
	private static function parseHint(code:String) {
		var tokens = parse(code);
		var scopes = new Map();
		var scope = "";
		var length = tokens.length;
		var start = 0;
		var end = -1;
		while (++end <= length) {
			// rest goes if we've reached the end of the script:
			if (end < length && !tokens[end].match(Define)) continue;
			//
			var locals = scopes != null ? scopes[scope] : null;
			if (locals == null) locals = new Map<String, Bool>();
			parseLocals(locals, tokens, start, end);
			scopes.set(scope, locals);
			//
			if (end + 2 < length) switch (tokens[end + 2]) {
				case Ident(s): scope = s;
				default:
			}
			//
			start = end;
		}
		return scopes;
	}
	/**
	 * Strips indentation equivalent to first line's from all lines.
	 */
	public static function unindent(code:String):String {
		var rx = ~/^[ \t]*\r?\n([ \t]+)/g;
		if (rx.match(code)) {
			return new EReg("\n" + rx.matched(1), "g").replace(code, "\n");
		} else return code;
	}
	public static function proc(
		code:String, preClassName:String, unIndent:Bool = true, hint:String, m:GMLMode
	):String {
		mode = m;
		if (unIndent) code = unindent(code);
		#if sys
		var multiVer = DocMdSys.templateVars["gml_variant"];
		if (multiVer != null) {
			var parts = code.split("\n---");
			var mv = Std.parseInt(multiVer);
			if (mv >= parts.length) mv = parts.length - 1;
			code = parts[mv];
		}
		#end
		var tokens = parse(code);
		var scopes = hint != null ? parseHint(hint) : null;
		hintLocals(tokens, scopes);
		return print(tokens, preClassName);
	}
}

/**
 * Some languages are sufficiently akin to GML to reuse the highlighter with minor changes.
 */
enum GMLMode {
	GML;
	Lua;
	AHK;
}

enum GmlToken {
	Spaces(s:String); // ` \t\r\n`
	Comment(s:String); // // some
	//
	Define; // #define
	Macro; // #macro
	Meta(s:String); // #region, etc.
	//
	Op(s:String); // +=
	Number(s:String); // 4
	CString(s:String); // 'text' "text"
	TString(s:String); // `text`
	Keyword(s:String); // exit
	Func(s:String); // place_meeting
	Builtin(s:String); // object_index
	Ident(s:String); // my_var
	Global(s:String); // global.some
	Local(s:String); // i
	Script(s:String); // scr_some
	Asset(s:String); // spr_some
	Field(s:String); // .field
	//
	ParOpen;
	ParClose;
	SqbOpen;
	SqbClose;
	CubOpen;
	CubClose;
}
