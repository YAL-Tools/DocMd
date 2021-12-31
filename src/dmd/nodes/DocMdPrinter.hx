package dmd.nodes;
import dmd.misc.StringBuilder;
import dmd.nodes.DocMdNode;
import dmd.tags.TagCode;
import dmd.tags.TagExec;
using dmd.nodes.DocMdNodeTools;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdPrinter {
	var buf = new StringBuilder();
	var sectionDepth = 0;
	static var isBlock = ~/^\s*<(?:div|p|section|header|footer|pre|h1|h2|h3|h4)\b/;
	function new() {
		//
	}
	function printNode(node:DocMdNode) {
		switch (node) {
			case Plain(text):
				buf.addString(StringTools.htmlEscape(text));
			case Html(html):
				buf.addString(html);
			case LineBreak:
				buf.addString("<br/>\n");
			case ParaBreak:
				// handled in printNodes
			case SepLine:
				buf.addString("<hr/>");
			case Bold(nodes):
				printNodesInTag(nodes, "b");
			case Italic(nodes):
				printNodesInTag(nodes, "i");
			case Strike(nodes):
				printNodesInTag(nodes, "s");
			case Sup(text):
				buf.addFormat("<sup>%s</sup>", text);
			case Link(nodes, url): {
				if (url.fastCodeAt(0) == "^".code) {
					var title = url.substring(1).replace('"', '&quot;');
					buf.addFormat('<abbr title="%s">', title);
					printNodes(nodes);
					buf.add('</abbr>');
				} else {
					buf.add('<a');
					var rels = [];
					while (url.length > 0) {
						switch (url.fastCodeAt(0)) {
							case "+".code: {
								buf.addString(' target="blank"');
								rels.push("noreferrer");
								rels.push("noopener");
							};
							case "!".code: rels.push("nofollow");
							default: break;
						}
						url = url.substring(1);
					}
					if (rels.length > 0) buf.addFormat(' rel="%s"', rels.join(" "));
					if (~/^[\w_\-% ]+$/g.match(url)) url = "#" + DocMd.makeID(url);
					buf.addFormat(' href="%s">', url);
					printNodes(nodes);
					buf.add('</a>');
				}
			}
			case AutoLink(nodes, sct):
				buf.addFormat('<a href="#%s">', sct);
				printNodes(nodes);
				buf.add('</a>');
			case InlineCode(text):
				buf.addFormat("<code>%s</code>", StringTools.htmlEscape(text));
			case Code(kind, text):
				TagCode.add(buf, kind, text);
			case Section(depth, title, permalink, meta, children): {
				var _depth = sectionDepth;
				var tags = meta == null ? [] : ~/,\s*/g.split(meta);
				var hasTags = tags.length > 0;
				var tagClass = hasTags ? "has-tags " + tags.map(function(s) {
					return "has-tag-" + DocMd.makeID(s);
				}).join(" ") : "";
				var tagHtml = hasTags ? '<span class="tags">' + tags.map(function(s) {
					return '<span class="tag-' + DocMd.makeID(s) + '">$s</span>';
				}).join("") + '</span>' : '';
				sectionDepth = (depth < 0) ? _depth + 1 : depth;
				switch (DocMd.genMode) {
					case Nested: {
						buf.addString('<section');
						if (hasTags) buf.addFormat(' class="%s"', tagClass);
						buf.addString('><header');
						if (permalink != null) {
							buf.addFormat(' id="%s"', permalink);
							//if (className != null) buf.addFormat(' class="%s"', className);
							buf.addFormat('><a href="#%s"', permalink);
							buf.add(' title="(permalink)"');
						} else if (hasTags) {
							buf.add('><span');
						}
						buf.add('>');
						printNodes(title);
						if (permalink != null) {
							buf.add('</a>');
						} else if (hasTags) {
							buf.add('</span>');
						}
						buf.add(tagHtml);
						buf.add('</header><article>');
						printNodes(children, true);
						buf.add('</article></section>');
					};
					case Visual: {
						buf.addFormat('<div');
						if (permalink != null) buf.addFormat(' id="%s"', permalink);
						//if (className != null) r.addFormat(' class="%s"', className);
						buf.add('><h2>');
						printNodes(title);
						buf.add('</h2>');
						printNodes(children, true);
						buf.add("</div>");
					};
					default: {
						var hi = depth >= 0 ? depth : sectionDepth + 1;
						buf.addFormat('<h%d', hi);
						if (hasTags) buf.addFormat(' class="%s"', tagClass);
						if (permalink != null) {
							buf.addFormat(' id="%s">', permalink);
							buf.addFormat('<a href="#%s" title="(permalink)">', permalink);
						} else {
							if (hasTags) buf.add('><span>'); else buf.add('>');
						}
						printNodes(title);
						buf.add(permalink != null ? '</a>' : '</span>');
						buf.add(tagHtml); 
						buf.addFormat('</h%d>', hi);
						printNodes(children, true);
					};
				}
				sectionDepth = _depth;
			};
			case NestList(kind, pre, items): {
				buf.addFormat("<%s>", kind);
				printNodes(pre);
				for (item in items) {
					buf.add('<li>');
					printNodes(item);
					buf.add('</li>');
				}
				buf.addFormat("</%s>", kind);
			};
			#if hscript
			case Exec(hx):
				var html = TagExec.exec(hx);
				buf.add(html);
			#end
			default:
				buf.add(node);
		}
	}
	function printNodesInTag(nodes:Array<DocMdNode>, tag:String, ?usePara:Bool) {
		buf.addFormat("<%s>", tag);
		printNodes(nodes, usePara);
		buf.addFormat("</%s>", tag);
	}
	function printNodes(nodes:Array<DocMdNode>, ?usePara:Bool) {
		if (usePara == null) usePara = nodes.needsPara();
		var inPara = false;
		inline function noPara():Void {
			if (inPara) {
				buf.add("</p>");
				inPara = false;
			}
		}
		for (i => node in nodes) {
			switch (node) {
				case ParaBreak:
					if (inPara) buf.add("</p>");
					var next = nodes[i + 1];
					if (next != null && !next.isBlock()) {
						buf.add("<p>");
						inPara = true;
					}
					continue;
				#if hscript
				case Exec(hx):
					var html = TagExec.exec(hx);
					if (isBlock.match(html)) noPara();
					buf.add(html);
					continue;
				#end
				case Code(kind, code):
					var tmp = new StringBuilder();
					TagCode.add(tmp, kind, code);
					var html = tmp.toString();
					if (isBlock.match(html)) noPara();
					buf.add(html);
					continue;
				default:
			}
			if (node.isBlock()) {
				noPara();
			} else {
				if (usePara && (i == 0 || !inPara)) {
					buf.add("<p>");
					inPara = true;
				}
			}
			printNode(node);
		}
		if (inPara) buf.add("</p>");
	}
	public static function print(nodes:Array<DocMdNode>) {
		var printer = new DocMdPrinter();
		//trace(nodes.join("\n"));
		printer.printNodes(nodes);
		return printer.buf.toString();
	}
}