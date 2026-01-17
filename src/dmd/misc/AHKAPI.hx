package dmd.misc;

/**
 * ...
 * @author YellowAfterlife
 */
class AHKAPI {
	static function keywords_init() {
		var r = new Map();
		var kd = [ //{
			"class", "extends", "this",
			"for", "while", "loop", "parse", "until", "in",
			"break", "continue",
			"and", "or", "xor", "not",
			"if", "else",
			"goto", "return",
			"local", "global", "static",
			"persistent",
		]; //}
		for (s in kd) r.set(s, true);
		return r;
	}
	public static var keywords:Map<String, Bool> = keywords_init();
	static function builtin_init() {
		var r = new Map();
		for (c in [
			"true", "false",
		]) r.set(c, true);
		for (v in [
			"A_IsUnicode", "A_ScriptHwnd", "A_ScriptDir"
		]) r.set(v, true);
		return r;
	}
	public static var builtin:Map<String, Bool> = builtin_init();
}