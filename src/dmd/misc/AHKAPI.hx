package dmd.misc;

/**
 * ...
 * @author YellowAfterlife
 */
class AHKAPI {
	static function keywords_init() {
		var r = new Map();
		var kd = [ //{
			"class", "extends",
			"for", "while", "loop", "until",
			"break", "continue",
			"and", "or", "xor", "not",
			"if", "else",
			"goto", "return",
			"local", "global",
			"persistent",
		]; //}
		for (s in kd) r.set(s, true);
		return r;
	}
	public static var keywords:Map<String, Bool> = keywords_init();
}