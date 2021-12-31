package dmd.auto;
import haxe.macro.Type.ModuleType;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdAutoEl {
	public var moduleType:ModuleType;
	public var text:String;
	public var children:Array<DocMdAutoEl> = [];
	public var idMap:Map<String, DocMdAutoSection> = new Map();
	public var order:Float = 0;
	public var sortIndex:Int;
	public function new(text:String, mt:ModuleType) {
		this.moduleType = mt;
		this.text = StringTools.trim(text);
	}
	public function print(out:StringBuf) {
		var hasText = text != null && text != "";
		if (hasText) out.add(text);
		var sep = hasText;
		for (el in children) {
			if (sep) out.add("\n"); else sep = true;
			el.print(out);
		}
		out.add("\n");
	}
	public function addSection(sct:DocMdAutoSection) {
		idMap[sct.id] = sct;
		children.push(sct);
	}
	static function sortRecProc(a:DocMdAutoEl, b:DocMdAutoEl):Int {
		if (a.order != b.order) return a.order < b.order ? -1 : 1;
		return a.sortIndex - b.sortIndex;
	}
	public function sortRec():Void {
		for (i in 0 ... children.length) {
			children[i].sortIndex = i;
			children[i].sortRec();
		}
		children.sort(sortRecProc);
	}
	public function toString():String {
		return '`$text`';
	}
}
