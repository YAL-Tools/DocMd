package dmd.misc;
import dmd.misc.StringBuilder;
import dmd.nodes.DocMdNode;
import dmd.nodes.DocMdPrinter;
using dmd.nodes.DocMdNodeTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdNav {
	public static var latest:String;
	static function printNode(buf:StringBuilder, node:DocMdNode, depth:Int){
		switch (node) {
			case Section(ref): {
				var hasChildren = ref.children.hasSections();
				if (ref.permalink == null && !hasChildren) return;
				
				var title = DocMdPrinter.print(ref.title);
				buf.addString("<li>");
				if (ref.permalink != null) {
					buf.addFormat('<a href="#%s">%s</a>', ref.permalink, title);
				} else {
					buf.addString(title);
				}
				var sub = new StringBuilder();
				for (node in ref.children) printNode(sub, node, depth + 1);
				if (sub != null) {
					buf.addFormat("<ul>%s</ul>", sub.toString());
				}
				buf.addFormat("</li>");
			};
			default:
		}
	}
	public static function print(nodes:Array<DocMdNode>){
		var buf = new StringBuilder();
		buf.addFormat('<nav class="navmenu"><ul>');
		for (node in nodes) printNode(buf, node, 0);
		buf.addFormat("</ul></nav>");
		
		latest = buf.toString();
		return latest;
	}
}