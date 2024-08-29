package dmd.auto;
import haxe.macro.Type.ModuleType;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdAutoSection extends DocMdAutoEl {
	public var id:String;
	public var title:String = null;
	public var prefix:String = null;
	public var suffix:String = null;
	public function new(id:String, mt:ModuleType) {
		super("", mt);
		this.id = id;
	}
	override public function print(out:StringBuf):Void {
		var isVar = id != null && DocMdAuto.injectableSections.exists(id);
		var _out:StringBuf;
		if (isVar) {
			_out = out;
			out = new StringBuf();
		} else _out = null;
		if (prefix != null && prefix != "") out.add(prefix + "\n");
		if (id != null || title != null) {
			var tb = new StringBuf();
			super.print(tb);
			var ts = tb.toString();
			var isEmpty = ts.trim() == "";
			if (isEmpty && order == 0x7FffFFff) return;
			if (title == null) {
				title = id;
				//trace("uh oh", this);
			}
			out.add('#[$title]($id) {');
			if (!isEmpty) { out.add("\n"); out.add(ts); }
			out.add('}\n');
		} else super.print(out);
		if (suffix != null && suffix != "") out.add(suffix + "\n");
		if (isVar) {
			var s = out.toString().rtrim().replace("\n", "\n\t");
			_out.add('```setmd $id\n');
			_out.add("\t" + s);
			_out.add('\n```\n');
		}
	}
	override public function toString():String {
		return '#[$title]($id){' + children.length + '}';
	}
}
