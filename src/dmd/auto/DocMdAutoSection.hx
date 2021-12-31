package dmd.auto;
import haxe.macro.Type.ModuleType;

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
		if (prefix != null && prefix != "") out.add(prefix + "\n");
		if (id != null || title != null) {
			out.add('#[$title]($id) {\n');
			super.print(out);
			out.add('}\n');
		} else super.print(out);
		if (suffix != null && suffix != "") out.add(suffix + "\n");
	}
	override public function toString():String {
		return '#[$title]($id){' + children.length + '}';
	}
}
