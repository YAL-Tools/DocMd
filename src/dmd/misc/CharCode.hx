package dmd.misc;

/**
 * ...
 * @author YellowAfterlife
 */
abstract CharCode(Int) from Int to Int {
	public var code(get, never):Int;
	private inline function get_code():Int return this;
	
	/** Returns whether this is a space or a tab character */
	public function isSpace0() {
		return (this == " ".code || this == "\t".code);
	}
	
	/** Returns whether this is a space/tab/newline character */
	public function isSpace1() {
		return (this > 8 && this < 14) || this == 32;
	}
	public function isSpace1_ni() return isSpace1();
	
	public function isIdent0() {
		return (this == "_".code
			|| (this >= "a".code && this <= "z".code)
			|| (this >= "A".code && this <= "Z".code)
		);
	}
	
	public function isIdent1() {
		return (this == "_".code
			|| (this >= "a".code && this <= "z".code)
			|| (this >= "A".code && this <= "Z".code)
			|| (this >= "0".code && this <= "9".code)
		);
	}
}