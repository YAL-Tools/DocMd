// ==UserScript==
// @name         HTML -> DMD
// @namespace    https://yal.cc
// @version      0.1
// @description  exposes a printDoc(element) function that converts HTML nodes to markdown/dmd
// @author       You
// @match        file:///*.html
// @match        https://yal.cc/*
// @match        https://ru.yal.cc/*
// @match        https://yellowafterlife.itch.io/*
// @grant        unsafeWindow
// ==/UserScript==

(function() {
	'use strict';
    if (typeof unsafeWindow == "undefined") window.unsafeWindow = window;
	//let doc = document.querySelector("#doc");
	//if (!doc) return;
	var root;
	let dmd = true;
	function prints(par, sep) {
		let out = "";
		let wasBlock = true;
		let index = 0;
		for (let node of par.childNodes) {
			let next = print(node, sep);
			let isBlock = /^[\r\n]/.test(next);
			if (wasBlock) {
				if (!isBlock) {
					out += sep;
					next = next.trimStart();
				} else if (/(?:```|\})$/.test(out)) {
					let sepl = sep.length;
					if (next.substr(0, sepl) == sep && next.substr(sepl, sepl) == sep) {
						next = next.substr(sepl);
					}
				}
			}
			if (isBlock) out = out.trimEnd();
			wasBlock = isBlock;
			out += next;
			index += 1;
		}
		if (/^[\r\n]/.test(out)) out = sep + out.trimStart();
		//if (out.charCodeAt(0) != "\n") out = sep + out.trimStart();
		return out.trimEnd();
	}
	function print(node, sep) {
		let out;
		let nodeName = node.nodeName;
		if (nodeName == "DIV" && node.classList.contains("gminfo")) {
			let pre = node.getElementsByTagName("pre")[0];
			return pre ? print(pre, sep) : "";
		}
		if (dmd && nodeName == "DIV" && node.classList.contains("item")) {
			let header = node.querySelector(":scope > .header");
			out = sep + "#[" + prints(header, sep).trim() + "]";
			let id = header.id;
			if (id) {
				let mt = /^([\w-]+)\s*[\(:]/.exec(header.innerText);
				if (mt && mt[1] == id) {
					out += "()";
				} else out += `(${id})`;
			}
			let content = node.querySelector(":scope > .content");
			if (content) {
				out += ` {` + prints(content, sep + "\t") + sep + `}`;
			} else out += "{}";
			return out;
		}
        if (node.classList && (node.classList.contains("related_post") || node.classList.contains("related_post_title"))) {
			return "";
        }
        switch (nodeName) {
			case "#comment": return "";
			case "SCRIPT":
				if (sep == "\n") return "";
				return "```raw" + sep + node.innerHTML.trim() + sep + "```";
			case "LI": {
				let h3 = node.getElementsByTagName("h3")[0];
				let nsep = sep + `\t`;
				if (h3) { // legacy dmd
					let name = h3.innerText;
					let id = h3.id || (/^\w+\(|^\w+/.test(name) ? "" : null);
					if (id) {
						let mt = /^(\w+)\(/.exec(name);
						if (mt && mt[1] == id) id = "";
					}
					out = sep + `#[${name}]`;
					if (id) out += `(${id})`;
					let ul = node.getElementsByTagName("div")[0];
					if (ul && ul.parentElement != node) ul = null;
					if (ul == null) {
						ul = node.getElementsByTagName("ul")[0];
						if (ul.parentElement != node) ul = null;
					}
					if (ul) {
						let txt = prints(ul, nsep);
						if (/^\s*\-\-\{[\s\S]+\}\s*$/.test(txt)) {
							txt = nsep + `--{` + txt + nsep + `}`;
						}
						out += ` {` + txt + sep + `}`;
					} else out += ` { }`;
				} else {
					out = sep + (dmd ? `--\t` : `* `) + prints(node, nsep).trim();
				}
			} break;
			case "BR": {
				out = "  " + sep;
			} break;
			case "P": {
				out = sep + prints(node, sep);
			} break;
			case "A": {
				let name = node.innerText;
				let href = node.getAttribute("href");
				if (href[0] == "#") href = href.substring(1);
				out = `[` + name + `]`;
				if (href != name) {
					href = href.replace(/\)/g, "%29");
					out += `(` + href + `)`;
				}
			} break;
			case "TT": case "CODE": {
				out = "`" + node.innerText.replace(/`/g, "\\`") + "`";
			} break;
			case "I": case "EM": {
				out = dmd ? "_" + node.innerText + "_" : "*" + node.innerText + "*";
			} break;
			case "B": case "STRONG": {
				out = dmd ? "*" + node.innerText + "*" : "**" + node.innerText + "**";
			} break;
			case "ABBR": {
				out = dmd ? `[${node.innerText}](^${node.title})` : `<abbr title="${node.title}">${node.innerText}</abbr>`;
			} break;
            case "PRE": case "CODE": {
				out = sep + "```" + sep + node.innerText.trim().replace(/\n/g, sep) + sep + "```";
			} break;
			case "UL": {
				if (node != root) {
					if (dmd) {
						out = sep + `--{` + prints(node, sep) + sep + `}`;
					} else out = sep + prints(node, sep);
				} else out = prints(node, sep);
			} break;
			case "OL": {
				if (node != root) {
					out = sep + `--#{` + prints(node, sep) + sep + `}`;
				} else out = prints(node, sep);
			} break;
			case "H1": case "H2": case "H3": {
				if (dmd) {
					out = sep + "}" + sep + "#[" + node.innerText + "] {";
				} else {
					out = sep + "#".repeat(parseInt(nodeName.charAt(1))) + " " + node.innerText;
				}
			} break;
			default: {
				let val = node.nodeValue || node.innerText;
				val = val.replace(/^\s+/, " ");
				val = val.replace(/\s+$/, " ");
				out = val.replace(/\s+/g, " ");
				//let vt = val.trim();
				//out = vt != "" ? val : "";
			}
		}
		return out;
	}
	unsafeWindow.printDoc = function(el, _dmd, out) {
		dmd = _dmd;
		if (el) root = el;
		if (!el) root = el = document.querySelector('.entry-content');
		if (!el) {
			el = document.querySelector("#doc");
			if (el) {
				root = el;
				el = el.parentElement;
			}
		}
		if (!el) root = el = document.querySelector('.formatted_description');
		if (out) {
			var textarea = document.createElement("textarea");
			textarea.value = prints(el, '\n');
			out.appendChild(textarea);
		} else return prints(el, '\n');
	};
	//console.log(prints(doc.parentElement, `\n`));
})();
//debugger;
let dmd = printDoc(document.querySelector("#doc"), document.querySelector(".page"));
//for (let line of dmd.split("\n")) console.log(line);