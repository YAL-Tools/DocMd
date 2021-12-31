package dmd.gml;
import dmd.misc.StringReader;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlVersion {
	//
	public static function verify(gml:String, v:Int):Bool {
		var q = new StringReader(gml);
		while (q.loop) {
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skip();
						while (q.loop) {
							switch (q.peek()) {
								case "\r".code, "\n".code: { }; // ->
								default: q.skip(); continue;
							}; break;
						}
					};
					case "*".code: {
						q.skip();
						while (q.loop) {
							if (q.peek() == "*".code) {
								q.skip();
								if (q.peek() == "/".code) {
									q.skip();
									break;
								}
							} else q.skip();
						}
					};
					default:
				};
				case "@".code: switch (q.peek()) {
					case '"'.code: {
						if (v < 2) return false;
						q.skip();
						while (q.loop) {
							c = q.read();
							if (c == '"'.code) break;
						}
						if (!q.loop) return false;
					};
					case "'".code: {
						if (v < 2) return false;
						q.skip();
						while (q.loop) {
							c = q.read();
							if (c == "'".code) break;
						}
						if (!q.loop) return false;
					};
					default:
				}; // case "@".code
				case "'".code: {
					if (v >= 2) {
						return false;
					} else {
						while (q.loop) {
							c = q.read();
							if (c == "'".code) break;
						}
						if (!q.loop) return false;
					}
				};
				case '"'.code: {
					if (v >= 2) {
						while (q.loop) {
							c = q.read();
							if (c == '"'.code) break;
							if (c == "\\".code) switch (c) {
								case "u".code: q.pos += 5;
								case "x".code: q.pos += 3;
								default: q.pos += 1;
							}
						}
						if (!q.loop) return false;
					} else {
						while (q.loop) {
							c = q.read();
							if (c == '"'.code) break;
						}
						if (!q.loop) return false;
					}
				};
				default:
			} // switch (c)
		}
		return true;
	}
	//
	public static function detect(gml:String):Int {
		gml += "\n";
		if (verify(gml, 2)) return 2;
		if (verify(gml, 1)) return 1;
		return 0;
	}
	//
	
	//
	/*public static function detect(gml:String):Int {
		var q = new StringReader(gml);
		while (q.loop) {
			c = q.read();
			switch (c) {
				case "/".code: procComment(q);
				case "@".code: switch (q.peek()) {
					case '"'.code: return 2;
					case "'".code: return 2;
					default:
				}; // case "@".code
				case "'".code: {
					while (q.loop) {
						c = q.peek();
						if (c == "'".code) { q.skip(); break; }
					}
					return q.loop ? 1 : 0;
				}
				case '"'.code: {
					while (q.loop) {
						c = q.peek();
						if (c == "'".code) { q.skip(); break; }
					}
					if (!q.loop) 
				};
				default:
			} // switch (c)
		}
		return -1;
	}*/
}
