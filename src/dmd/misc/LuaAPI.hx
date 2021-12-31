package dmd.misc;

/**
 * ...
 * @author YellowAfterlife
 */
class LuaAPI {
	static function keywords_init() {
		var r = new Map();
		var kd = [ //{
			"and",       "break",     "do",        "else",      "elseif",    "end",
			"false",     "for",       "function",  "goto",      "if",        "in",
			"local",     "nil",       "not",       "or",        "repeat",    "return",
			"then",      "true",      "until",     "while"
		]; //}
		for (s in kd) r.set(s, true);
		return r;
	}
	public static var keywords:Map<String, Bool> = keywords_init();
}