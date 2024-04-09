package dmd.nodes;
import dmd.nodes.DocMdNode;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdNodeTools {
	public static function hasParaBreak(nodes:Array<DocMdNode>):Bool {
		return nodes.indexOf(DocMdNode.ParaBreak) >= 0;
	}
	public static function toPlainText(nodes:Array<DocMdNode>):String {
		var b = new StringBuf();
		for (node in nodes) {
			switch (node) {
				case Plain(text): b.add(text);
				default:
			}
		}
		return b.toString();
	}
	public static function isBlock(node:DocMdNode):Bool {
		return switch (node) {
			case Code(_, _): true;
			case Section(_, _, _, _): true;
			case SepLine: true;
			case NestList(kind, pre, items): true;
			default: false;
		}
	}
	public static function needsPara(nodes:Array<DocMdNode>):Bool {
		if (hasParaBreak(nodes)) return true;
		for (node in nodes) if (isBlock(node)) return true;
		return false;
	}
	public static function hasSections(nodes:Array<DocMdNode>):Bool {
		for (node in nodes) {
			if (node.match(Section(_, _, _, _))) {
				return true;
			}
		}
		return false;
	}
}