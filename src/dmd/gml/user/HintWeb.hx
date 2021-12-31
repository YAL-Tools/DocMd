package dmd.gml.user;
//
import dmd.gml.GmlAPI;
import dmd.gml.GmlData;
import dmd.gml.GmlVersion;
import dmd.gml.HintGML;
import js.html.Element;
import js.html.HTMLDocument;
import dmd.gml.user.HintWebMcr.*;
import js.html.Window;
using StringTools;
//

/**
 * ...
 * @author YellowAfterlife
 */
class HintWeb {
	public static var document(get, never):HTMLDocument;
	private static inline function get_document():HTMLDocument {
		return untyped __js__("document");
	}
	//
	public static var window(get, never):Window;
	private static inline function get_window():Window {
		return untyped __js__("window");
	}
	//
	public static function main() {
		//
		var host = document.location.hostname;
		if (host.substring(0, 4) == "www.") host = host.substring(4);
		//
		#if !gmdoc
		var isLight = false, q1 = "pre";
		switch (host) {
			case "reddit.com": {
				q1 = ".md pre";
				isLight = document.querySelector('#header-img.default-header') != null;
			};
			case "forum.yoyogames.com": {
				q1 = ".bbCodeBlock pre";
				var themer = document.querySelector('a[href^="index.php?misc/style"]');
				if (themer != null) {
					var theme = themer.textContent.toLowerCase();
					isLight = (theme.indexOf("light") >= 0);
				}
			};
			case "forum.hellroom.ru": {
				q1 = "div.code";
				isLight = document.querySelector(
					'link[rel="stylesheet"][href*="/Themes/Ps_Black"]'
				) == null;
			};
		}
		#else
		var q1 = "p.code";
		#end
		var q1md = q1 + ".gmlmd";
		var css = loadCode("src/gml/user/hint.css").replace("pre", q1md);
		#if !gmdoc
		if (isLight) css += loadCode("src/gml/user/hint-light.css").replace("pre", q1md);
		#else
		css = css.replace(".uv { color: #B2B1FF }", ".uv { color: #C0C0C0 }");
		#end
		//
		var cssEl = document.createStyleElement();
		cssEl.type = "text/css";
		cssEl.innerHTML = css;
		cssEl.id = "cc_yal_gmlhint";
		document.body.appendChild(cssEl);
		//
		#if !gmdoc
		GmlAPI.loadEntries(GmlData.raw);
		#else
		
		#end
		var q1n = q1 + ":not(.gmlmd):not(.nonmd)";
		function check() {
			for (_el in document.querySelectorAll(q1n)) {
				var el:Element = cast _el;
				#if (gmdoc)
				var prev = el.previousElementSibling;
				if (prev != null && prev.textContent.indexOf("Returns:") >= 0) {
					el.classList.add("nonmd");
					continue;
				}
				#end
				var code = el.innerText;
				if (code == null) code = el.textContent;
				//
				var v = GmlVersion.detect(code);
				if (v == 0) {
					el.classList.add("nonmd");
					continue;
				}
				HintGML.version = v;
				//
				var html = HintGML.proc(code, null, false);
				if (false) {
					el.classList.add("has-line-numbers");
					var table = document.createTableElement();
					var row = 0;
					for (line in html.split("\n")) {
						var tr = document.createTableRowElement();
						//
						var td = document.createTableCellElement();
						td.className = "code-line-number";
						td.setAttribute("data-line-number", Std.string(++row));
						tr.appendChild(td);
						//
						td = document.createTableCellElement();
						td.className = "code-line";
						td.innerHTML = line;
						tr.appendChild(td);
						//
						table.appendChild(tr);
					}
					el.innerHTML = "";
					el.appendChild(table);
				} else {
					#if !gmdoc
					switch (host) {
						case "reddit.com": {
							el.classList.add("background-important");
							html = '<code style="background-color:transparent!important">$html</code>';
						};
						case "forum.hellroom.ru": {
							html = '<pre style="'
								+ (isLight
									? 'margin:0'
									: 'margin:4px;font-size:9pt'
								) + '">$html</pre>';
						};
					}
					#else
					el.style.whiteSpace = "pre-wrap";
					#end
					el.classList.add("gmlmd");
					el.innerHTML = html;
				}
			}
		}
		#if (!gmdoc)
		window.setInterval(check, 1700);
		#end
		check();
	}
}
