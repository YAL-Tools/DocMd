package dmd.misc;

import haxe.io.Bytes;
import haxe.io.Path;
import sf.gml.SfGmx;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileSeek;
import dmd.misc.StringBuilder;

class GenSprites {
	static function main() {
		var args = Sys.args();
		if (args.length < 3) {
			Sys.println("docmd-sprites some.project.gmx some.dmd some.png tempdir");
			return;
		}
		var path = args[0];
		var pathMd = args[1];
		var pathTh = args[2];
		var tmp = args[3];
		var dir = Path.directory(path);
		if (!FileSystem.exists(tmp)) {
			FileSystem.createDirectory(tmp);
		}
		var gmx:SfGmx = SfGmx.parse(File.getContent(path));
		var out = new StringBuilder();
		var found = 0;
		function rec(node:SfGmx, tab:String, path:String) {
			if (node.name == "sprites") {
				var name = node.get("name");
				var id = StringTools.urlEncode(name);
				if (path != "") id = path + "_" + id;
				out.addFormat("\r\n%s#[%s](%s) {", tab, name, id);
				var ntab = tab + "\t";
				for (el in node.children) rec(el, ntab, id);
				out.addFormat("\r\n%s}", tab);
			} else {
				var name = node.text;
				var slash = name.lastIndexOf("\\");
				name = name.substring(slash + 1);
				var th0 = Path.join([dir, "sprites", "images", name + "_0.png"]);
				var th1 = Path.join([tmp, StringTools.lpad("" + found, "0", 4) + ".png"]);
				var tx = -32, ty = -32;
				if (FileSystem.exists(th0)) {
					if (!FileSystem.exists(th1)) {
						Sys.command('magick "$th0" -thumbnail "32x32\\>" -background none -gravity center -extent 32x32 "$th1"');
					}
					ty = Std.int(found / 100) * 32;
					tx = (found % 100) * 32;
					found += 1;
				}
				out.addFormat('\r\n%s```raw <div class="asset" id="%s">', tab, name);
				out.addFormat(
					'<a href="#%s" class="thumb" style="background-position: %dpx %dpx" title="(permalink)"></a>',
					name, -tx, -ty);
				out.addFormat('<span class="label">%s</span>', name);
				out.addFormat('</div>```');
			}
		}
		for (el in gmx.find("sprites").children) {
			rec(el, "", "");
		}
		//
		Sys.println("Making atlas now");
		for (row in 0 ... Math.floor(found / 100) + 1) {
			var r2 = StringTools.lpad("" + row, "0", 2);
			var rx = '$tmp/row$r2.png';
			if (!FileSystem.exists(rx))
			Sys.command('magick "$tmp/$r2[0-9][0-9].png" -background none +append "$rx"');
		}
		if (!FileSystem.exists(pathTh)) {
			Sys.command('magick "$tmp/row[0-9][0-9].png" -background none -append "$pathTh"');
		}
		File.saveContent(pathMd, out.toString().substring(2));
		//
		//Sys.command('magick "$tmp/[0-9][0-9][0-9][0-9].png" -append "$dir/thumbs.png"');
		//FileSystem.deleteDirectory(tmp);
		//Sys.command('magick "$from" -thumbnail 16x16 -gravity center -extent 16x16 "$to"');
	}
}

