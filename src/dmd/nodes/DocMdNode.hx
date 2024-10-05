package dmd.nodes;
import dmd.nodes.DocMdPos;

/**
 * ...
 * @author YellowAfterlife
 */
enum DocMdNode {
	Plain(text:String);
	Html(html:String);
	
	LineBreak;
	ParaBreak;
	SepLine;
	
	// Simple:
	Bold(nodes:Array<DocMdNode>);
	Italic(nodes:Array<DocMdNode>);
	Strike(nodes:Array<DocMdNode>);
	Sup(text:String);
	
	// Inline:
	Link(nodes:Array<DocMdNode>, url:String);
	AutoLink(nodes:Array<DocMdNode>, sct:String);
	InlineImage(src:String, alt:String);
	
	// Blocks:
	InlineCode(text:String);
	Code(kind:String, text:String, pos:DocMdPos);
	NestList(kind:String, pre:Array<DocMdNode>, items:Array<Array<DocMdNode>>);
	Section(ref:DocMdSection);
	Exec(code:String, pos:DocMdPos);
}
class DocMdSection {
	public var depth:Int;
	public var title:Array<DocMdNode>;
	public var permalink:String;
	public var meta:String;
	public var children:Array<DocMdNode>;
	public function new(depth:Int, title:Array<DocMdNode>, permalink:String, meta:String, children:Array<DocMdNode>) {
		this.depth = depth;
		this.title = title;
		this.permalink = permalink;
		this.meta = meta;
		this.children = children;
	}
}