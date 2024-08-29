package dmd.nodes;
import dmd.misc.StringReader;
import dmd.nodes.DocMdNode;
using dmd.nodes.DocMdNodeTools;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdParser {
	var start = 0;//(default, set) = 0;
	inline function set_start(i:Int):Int {
		trace('start is now $i');
		start = i;
		return i;
	}
	
	var reader:StringReader;
	var sectionPrefix = "";
	var headerDepth = 0;
	function new(dmd:String) {
		reader = new StringReader(dmd);
	}
	
	static function makeID(s:String) {
		s = s.replace(" ", "-");
		s = s.replace("'", "");
		s = ~/[^\w\-_\.]/g.replace(s, "");
		return s;
	}
	
	public static var trimPlainIndentation = false;
	static var trimPlainIndentation_rx = ~/\n\s+/gm;
	function flush(out:Array<DocMdNode>, till:Int = -1) {
		if (till < 0) till = reader.pos;
		if (till > start) {
			var text = reader.substring(start, till);
			if (trimPlainIndentation) {
				text = trimPlainIndentation_rx.replace(text, "\n");
			}
			//trace(start, till, '<<$text>>');
			out.push(Plain(text));
		}
	}
	inline function flushSkip(out:Array<DocMdNode>, n:Int = 1) {
		flush(out);
		reader.skip(n);
	}
	
	function readNodesTillAfter(end:String):Array<DocMdNode> {
		start = reader.pos;
		var nodes = [];
		var endLen = end.length;
		var endChar = endLen == 0 ? end.charCodeAt(0) : -1;
		while (reader.loop) {
			if (endChar >= 0) {
				if (reader.peek() == endChar) {
					flushSkip(nodes);
					start = reader.pos;
					return nodes;
				}
			} else {
				if (reader.peekn(endLen) == end) {
					flushSkip(nodes, endLen);
					start = reader.pos;
					return nodes;
				}
			}
			read(nodes);
		}
		flush(nodes);
		start = reader.pos;
		return nodes;
	}
	
	function readNestList(kind:String):DocMdNode {
		var pre = [];
		var nodes = pre;
		var items = [];
		start = reader.pos;
		inline function flushListItem(skip:Int):Void {
			flushSkip(nodes, skip);
			nodes = [];
			items.push(nodes);
			start = reader.pos;
		}
		while (reader.loop) {
			var c = reader.peek();
			switch (c) {
				case "-".code: // --
					if (reader.peek(1) != "-".code) {
						if (reader.isLineStart(reader.pos)) {
							flushListItem(1);
							continue;
						}
					} else switch (reader.peek(2)) {
						case "}".code:
							flushSkip(nodes, 2);
							break;
						case "-".code, "{".code:
							// don't consume `---` and sub-lists!
						default: // next list item!
							flushListItem(2);
							continue;
					}
				case "}".code:
					flushSkip(nodes);
				break;
			}
			read(nodes);
		}
		return NestList(kind, pre, items);
	}
	
	function read(out:Array<DocMdNode>) {
		var c = reader.peek();
		var from = reader.pos;
		switch (c) {
			case "\n".code: {
				if (reader.pos >= 2
					&& reader.peek( -1) == " ".code
					&& reader.peek( -2) == " ".code
				) {
					flush(out);
					out.push(LineBreak);
					start = reader.pos + 1;
				}
				reader.skip();
				reader.skipLineSpaces();
				if (reader.peek() == "\n".code) {
					flush(out);
					out.push(ParaBreak);
					start = reader.pos++;
				}
			};
			case 92: { // backslash
				flushSkip(out);
				c = reader.read();
				switch (c) {
					case " ".code:
						// OK!
					case "\n".code:
						out.push(LineBreak);
					default:
						out.push(Plain(String.fromCharCode(c)));
				}
				start = reader.pos;
			};
			case "[".code: {
				flushSkip(out);
				var label = readNodesTillAfter("]");
				if (reader.skipIfEqu("(".code)) {
					start = reader.pos;
					// URLs might contain () so make up for that:
					var url = reader.readBalanced("(".code, ")".code);
					out.push(Link(label, url));
				} else {
					out.push(AutoLink(label, makeID(label.toPlainText())));
				}
				start = reader.pos;
			};
			case "!".code if (reader.peek(1) == "[".code): { // ![alt](url.png)
				flushSkip(out, 2);
				var alt = reader.readTillAfter("]".code);
				if (reader.skipIfEqu("(".code)) {
					var src = reader.readTillAfter(")".code);
					out.push(InlineImage(src, alt));
				} else {
					out.push(InlineImage(alt, ""));
				}
				start = reader.pos;
			};
			case "*".code: {
				flushSkip(out);
				out.push(Bold(readNodesTillAfter("*")));
				start = reader.pos;
			};
			case "_".code if (reader.peek( -1).isSpace1()): {
				flushSkip(out);
				out.push(Italic(readNodesTillAfter("_")));
				start = reader.pos;
			};
			case "^".code: {
				c = reader.peek(1);
				if (c == "[".code || c == "(".code) { // ^(sup), ^[cite]
					flushSkip(out, 2);
					var isSqb = c == "[".code;
					var text = reader.readTillAfter(isSqb ? "]".code : ")".code);
					if (isSqb) text = '[$text]';
					out.push(Sup(text));
					start = reader.pos;
				} else reader.skip();
			}
			case "#".code if (reader.peek(1) == "[".code): { // #[title](tag) { nodes }
				flushSkip(out, 2);
				var title = readNodesTillAfter("]");
				var permalink:String, meta:String = null;
				if (reader.skipIfEqu("(".code)) {
					permalink = reader.readTillAfter(")".code);
					
					// support #[title](permalink|...tags)
					var clSep = permalink.indexOf("|");
					if (clSep >= 0) {
						meta = permalink.substring(clSep + 1);
						permalink = permalink.substring(0, clSep);
					}
					
					/**
					#[Category](+cat) {
						#[Item 1](-i1) {}
						#[Item 2](-i2) {}
					}
					acts like 
					#[Category](cat) {
						#[Item 1](cat-i1) {}
						#[Item 2](cat-i2) {}
					}
					**/
					var pmFirstChar = permalink.length > 0 ? permalink.charAt(0) : null;
					var pmFirstSpec = pmFirstChar != null && "+-_.".contains(pmFirstChar);
					if (pmFirstSpec) {
						permalink = permalink.substring(1);
					}
					
					// auto-generate permalink if blank
					if (permalink == "") {
						static var rxAuto = new EReg("^"
							+ "(" + "[\\w\\-\\.]+" + ")" // a_b-c.d
							+ "\\s*" + "[\\(:=]" // f() / v:t / c = 0
						, "");
						var text = title.toPlainText();
						if (rxAuto.match(text)) {
							permalink = rxAuto.matched(1);
						} else permalink = makeID(text);
					}
					
					//
					if (pmFirstSpec) {
						if (pmFirstChar == "+") {
							sectionPrefix = permalink;
						} else {
							permalink = sectionPrefix + pmFirstChar + permalink;
						}
					}
				} else permalink = null;
				//
				for (i => node in title) switch (node) {
					case Plain(text):
						var pos = text.indexOf(")->");
						if (pos >= 0) {
							title[i] = Plain(text.substring(0, pos + 1));
							title.insert(i + 1, Html('&#8203;<span class="ret-arrow">&#10140;</span>'));
							title.insert(i + 2, Plain(text.substring(pos + 3)));
							break;
						}
					default:
				}
				//
				reader.readTillAfter("{".code);
				var children = readNodesTillAfter("}");
				var section = new DocMdSection( -1, title, permalink, meta, children);
				out.push(Section(section));
				start = reader.pos;
			};
			case "#".code if (reader.peek(1) == "#".code && reader.peek(2) == "{".code): {// ##{ OL }
				flushSkip(out, 3);
				out.push(readNestList("ol"));
				start = reader.pos;
			};
			case "#".code if (reader.isLineStart(from)): {
				var hn = 0;
				while (reader.peek() == "#".code) { reader.skip(); hn++; }
				reader.skipLineSpaces();
				var title, id:String = null;
				if (reader.skipIfEqu("[".code)) {
					title = readNodesTillAfter("]");
					if (reader.skipIfEqu("(".code)) {
						id = reader.readTillAfter(")".code);
						if (id == "") {
							var rx = ~/^([\w-]+)\s*[\(:]/g;
							var text = title.toPlainText();
							if (rx.match(text)) {
								id = rx.matched(1);
							} else id = makeID(text);
						} else if (id.startsWith("#")) id = id.substring(1);
					}
				} else {
					title = readNodesTillAfter("\n");
				}
				var section = new DocMdSection(hn, title, id, null, []);
				out.push(Section(section));
				start = reader.pos;
			};
			case "`".code if (reader.peek(1) == "`".code && reader.peek(2) == "`".code): {
				// figure out spacing for the line with ```
				var lineStart = reader.pos;
				while (lineStart > 0) {
					if (reader.get(lineStart - 1) == "\n".code) break; else lineStart--;
				}
				var lineIter = lineStart;
				while (lineIter < reader.pos) {
					switch (reader.get(lineIter)) {
						case " ".code, "\t".code: lineIter++;
						default: break;
					}
				}
				var lineIndent = lineIter == from ? reader.substring(lineStart, lineIter) : null;
				
				flushSkip(out, 3);
				var mode = reader.readIdent();
				//
				var code:String = null;{
					var codeStart = reader.pos;
					var result:String = null;
					var lineIndentLen = lineIndent != null ? lineIndent.length : -1;
					var sameLine = true;
					while (reader.loop) {
						if (sameLine && reader.peek() == "\n".code) sameLine = false;
						if (reader.peek() == "`".code
							&& reader.peek(1) == "`".code
							&& reader.peek(2) == "`".code
							&& (sameLine || lineIndent == null || (
								reader.peek(-lineIndentLen - 1) == "\n".code
								&& reader.substr(reader.pos - lineIndentLen, lineIndentLen) == lineIndent
							))
						) {
							var codeEnd = reader.pos;
							if (!sameLine && lineIndent != null) codeEnd -= lineIndentLen;
							code = reader.substring(codeStart, codeEnd);
							reader.pos += 3;
							break;
						} else reader.skip();
					}
					if (code == null) code = reader.substring(codeStart, reader.pos);
				}
				//
				//trace(mode, '<<$code>>');
				out.push(Code(mode, code));
				start = reader.pos;
			};
			case "-".code if (reader.peek(1) == "-".code && reader.peek(2) == "-".code): { // --- HR
				flush(out);
				while (reader.peek() == "-".code) reader.skip();
				out.push(SepLine);
				start = reader.pos;
			};
			case "-".code if (reader.peek(1) == "-".code && reader.peek(2) == "{".code): { // --{ UL }
				flushSkip(out, 3);
				out.push(readNestList("ul"));
				start = reader.pos;
			};
			case "<".code if (reader.peekn(4) == "<!--"): {
				flush(out);
				reader.readTillAfterStr("-->");
				start = reader.pos;
			};
			case "~".code if (reader.peek(1) == "~".code): {
				flushSkip(out, 2);
				out.push(Strike(readNodesTillAfter("~~")));
				start = reader.pos;
			};
			case "`".code: {
				flushSkip(out);
				start = reader.pos;
				var b = new StringBuf();
				var s:String = null;
				while (reader.loop) {
					var c = reader.read();
					if (c == "\\".code) {
						c = reader.peek();
						if (c == "`".code || c == "\\".code) {
							b.add(reader.substring(start, reader.pos - 1));
							b.addChar(c);
							reader.skip();
							start = reader.pos;
						}
					} else if (c == "`".code) {
						if (b.length > 0) {
							b.add(reader.substring(start, reader.pos - 1));
							s = b.toString();
						} else s = reader.substring(start, reader.pos - 1);
						break;
					}
				}
				if (s != null) out.push(InlineCode(s));
				start = reader.pos;
			};
			case "$".code if (reader.peek(1) == "{".code): {
				flushSkip(out, 2);
				var depth = 1;
				while (reader.loop) {
					c = reader.peek();
					switch (c) {
						case "{".code:
							depth++;
							reader.skip();
						case "}".code:
							if (--depth <= 0) break;
							reader.skip();
						case '"'.code, "'".code:
							reader.skip();
							reader.readTillAfter(c);
						default:
							reader.skip();
					}
				}
				var hx = reader.substring(from + 2, reader.pos);
				if (reader.loop) reader.skip();
				out.push(Exec(hx));
				start = reader.pos;
			};
			case "$".code if (reader.peek(1) == "[".code): { // $[func], $[func](arg)
				flushSkip(out, 2);
				var func = reader.readTillAfter("]".code);
				var hx;
				if (reader.skipIfEqu("(".code)) {
					start = reader.pos;
					var arg = reader.readTillAfter(")".code);
					hx = func + '(' + haxe.Json.stringify(arg) + ');';
				} else {
					hx = func + "();";
				}
				out.push(Exec(hx));
				start = reader.pos;
			};
			case "%".code if (reader.peek(1) == "{".code): {
				flushSkip(out, 2);
				for (node in readNodesTillAfter("}")) out.push(node);
				start = reader.pos;
			};
			default: reader.skip();
		}
	}
	
	public static function parse(dmd:String) {
		dmd = StringTools.replace(dmd, "\r", "");
		var parser = new DocMdParser(dmd);
		var nodes = [];
		while (parser.reader.loop) parser.read(nodes);
		parser.flush(nodes);
		return nodes;
	}
}