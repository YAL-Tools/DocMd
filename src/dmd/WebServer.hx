package dmd;
import haxe.CallStack;
import haxe.io.Bytes;
import haxe.io.Path;
import dmd.misc.MimeType;
import sys.FileSystem;
import sys.io.File;
import sys.net.Host;
import sys.net.Socket;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class WebServer {
	static inline function addln(b:StringBuf, s:String) {
		b.add(s);
		b.addChar("\r".code);
		b.addChar("\n".code);
	}
	static var status:Int;
	static var noBody:Bool = false;
	static var mimeType:String = null;
	static var isIndex:Bool = false;
	static function error(i:Int, s:String = "") {
		status = i; return Bytes.ofString(s);
	}
	//
	static var reqURL:String = null;
	static function handle(req:String):Bytes {
		noBody = false;
		mimeType = MimeType.defValue;
		isIndex = false;
		reqURL = null;
		try {
			status = 200;
			//
			var lp = req.indexOf("\r");
			if (lp >= 0) req = req.substring(0, lp);
			//
			var sp = req.indexOf(" ");
			var kind = req.substring(0, sp);
			noBody = switch (kind) {
				case "GET": false;
				case "HEAD": true;
				default: return error(405, 'Wrong kind $kind');
			}
			sp += 1;
			//
			var qp = req.indexOf("?");
			if (qp < 0) qp = req.indexOf("#");
			if (qp < 0) qp = req.indexOf(" ", sp);
			if (qp < 0) qp = req.length;
			//
			var url = req.substring(sp, qp);
			reqURL = url;
			//trace(url);
			switch (url) {
				case "/", "/index.html": {
					isIndex = true;
					mimeType = MimeType.get("html");
					return Bytes.ofString(DocMdSys.lastOutput);
				}
				default: {
					var dir = DocMdSys.dir;
					var full = Path.normalize(dir + url);
					mimeType = MimeType.get(Path.extension(full));
					if (full.startsWith(dir) && FileSystem.exists(full)) {
						try {
							return File.getBytes(full);
						} catch (x:Dynamic) {
							return error(500, "" + x);
						}
					} else return error(404);
				}
			}
			//return 'hello <$url> [$req]';
		} catch (x:Dynamic) {
			Sys.println("An error occurred: " + x);
			return error(500);
		}
	}
	//
	public static function start(port:Int) {
		dmd.misc.MimeType.init();
		var server = new Socket();
		try {
			server.bind(new Host("0.0.0.0"), port);
			server.listen(8);
		} catch (e:Dynamic) {
			Sys.println('Failed to start server on port $port:');
			Sys.println(Std.string(e));
			return;
		}
		var bytes = Bytes.alloc(16384);
		var time = 0.;
		Sys.println('Listening on port $port...');
		while (true) try {
			var client = server.accept();
			var length = client.input.readBytes(bytes, 0, bytes.length);
			var request = bytes.getString(0, length);
			var peer = client.peer();
			var origin = peer.host.toString() + ":" + peer.port;
			var result = handle(request);
			if (status != 200) {
				Sys.println('[$origin] HTTP $status $reqURL');
			}
			var sb = new StringBuf();
			var rl = result.length;
			if (noBody && isIndex) {
				if (DocMdSys.lastOutputTime > time) rl += 1024;
			}
			addln(sb, 'HTTP/1.1 $status OK');
			addln(sb, "Server: docmd");
			var ct = "Content-Type: " + mimeType;
			if (mimeType.startsWith("text/")) ct += "; charset=utf-8";
			addln(sb, ct);
			addln(sb, "Connection: close");
			addln(sb, "Content-length: " + rl);
			addln(sb, "Content-Range: bytes 0-" + rl + "/" + (rl + 1));
			addln(sb, "X-Content-Type-Options: nosniff");
			addln(sb, "Cache-Control: no-cache");
			addln(sb, "Access-Control-Allow-Origin: *");
			addln(sb, "Accept-Ranges: bytes");
			addln(sb, "");
			client.output.writeString(sb.toString());
			//client.write(sb.toString());
			if (!noBody) {
				time = DocMdSys.lastOutputTime;
				client.output.writeBytes(result, 0, rl);
				//client.write(result);
			}
			client.output.flush();
			client.close();
		} catch (x:Dynamic) {
			Sys.println(x);
			Sys.println(CallStack.toString(CallStack.exceptionStack()));
		}
	}
}
