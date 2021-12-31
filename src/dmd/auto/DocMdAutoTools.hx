package dmd.auto;

/**
 * ...
 * @author YellowAfterlife
 */
class DocMdAutoTools {
	public static function toSnakeCase(s:String):String {
		var n = s.length;
		// early exit if the string is already in snake_case:
		var i = -1;
		while (++i < n) {
			var c = StringTools.fastCodeAt(s, i); // or s.charCodeAt(i)
			if (c >= "A".code && c <= "Z".code) break;
		}
		if (i >= n) return s;
		// otherwise form it via a string buffer:
		var r = new StringBuf();
		var p = 0;
		for (i in 0 ... n) {
			var c = StringTools.fastCodeAt(s, i);
			if (c >= "A".code && c <= "Z".code) {
				if (p >= "a".code && p <= "z".code
				 || p >= "0".code && p <= "9".code) { // "eC" -> "e_c"
					r.addChar("_".code);
				}
				r.addChar(c + ("a".code - "A".code));
			} else r.addChar(c);
			p = c;
		}
		return r.toString();
	}
}
