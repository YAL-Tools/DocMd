package dmd.auto;
import haxe.macro.Expr;
import haxe.macro.Context;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdAutoBuilder {
	public static var autoOrder:Map<String, Float> = new Map();
	public static var root:DocMdAutoSection;
	public static var findZeroPath:Array<Dynamic> = [["uncategorized", "Uncategorized", 999999]];
	public static function find(chain:Array<Dynamic>, at:Position, ?from:DocMdAutoSection):DocMdAutoSection {
		var cur = from != null ? from : root;
		if (chain == null) chain = findZeroPath;
		for (item in chain) {
			var next:DocMdAutoSection;
			inline function checkAutoOrder(id:String):Void {
				var ord = autoOrder[id];
				if (ord != null) next.order = ord;
			}
			if (Std.is(item, String)) {
				next = cur.idMap[item];
				if (next == null) {
					next = new DocMdAutoSection(item, null);
					next.title = item;
					checkAutoOrder(item);
					cur.addSection(next);
				}
			} else if (Std.is(item, Array)) {
				var arr:Array<Dynamic> = item;
				var id = arr[0];
				if (!Std.is(id, String)) {
					throw Context.error("Not a valid ID: " + arr[0], at);
				}
				next = cur.idMap[id];
				if (next == null) {
					next = new DocMdAutoSection(id, null);
					checkAutoOrder(id);
					cur.addSection(next);
				}
				next.title = arr[1];
				if (arr[2] != null) next.order = arr[2];
				if (arr[3] != null) next.text = arr[3];
			} else {
				throw Context.error("Unknown path item " + item, at);
			}
			cur = next;
		}
		return cur;
	}
}
