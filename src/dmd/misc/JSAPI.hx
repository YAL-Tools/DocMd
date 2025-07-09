package dmd.misc;

/**
 * ...
 * @author YellowAfterlife
 */
class JSAPI {
	static function keywords_init() {
		var r = new Map();
		var kd = [ //{
			"abstract", "arguments", "boolean", "break", "byte",
			"case", "catch", "char", "const", "continue",
			"debugger", "default", "delete", "do", "double",
			"else", "eval", "false", "final", "finally",
			"float", "for", "function", "goto", "if",
			"implements", "in", "instanceof", "int", "interface",
			"long", "native", "new", "null", "package",
			"private", "protected", "public", "return", "short",
			"static", "switch", "synchronized", "this", "throw",
			"throws", "transient", "true", "try", "typeof",
			"var", "void", "volatile", "while", "with",
			"yield",
			//
			"awaits", "class", "enum", "export",
			"extends", "import", "let", "super",
		]; //}
		for (s in kd) r.set(s, true);
		return r;
	}
	public static var keywords:Map<String, Bool> = keywords_init();
}