package dmd.nodes;

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
	Code(kind:String, text:String);
	NestList(kind:String, pre:Array<DocMdNode>, items:Array<Array<DocMdNode>>);
	Section(depth:Int, title:Array<DocMdNode>, permalink:String, meta:String, children:Array<DocMdNode>);
	Exec(code:String);
}