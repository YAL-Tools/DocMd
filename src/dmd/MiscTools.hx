package dmd;

/**
 * ...
 * @author YellowAfterlife
 */
class MiscTools {
	public static function each(rx:EReg, s:String, fn:EReg->Void) {
		var p = 0;
		//var count = 0;
		while (rx.matchSub(s, p)) {
			fn(rx);
			var mp = rx.matchedPos();
			var p1 = mp.pos + mp.len;
			//trace(rx.matched(0), p, p1, mp);
			#if macro
			if (p1 <= p) {
				p++;
			} else 
			#end
			p = p1;
			//if (++count >= 1024*4) break;
		}
	}
}
