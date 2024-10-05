package dmd.nodes;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdPos {
	public var file:String;
	public var row:Int;
	public function new(file:String, row:Int = 0) {
		this.file = file;
		this.row = row;
	}
}