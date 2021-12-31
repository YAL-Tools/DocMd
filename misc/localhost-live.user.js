// ==UserScript==
// @name      live.js@localhost
// @namespace https://yal.cc
// @version   1.0
// @author    YellowAfterlife
// @match     http://localhost:4000/*
// @grant     none
// ==/UserScript==
/*
	Live.js - One script closer to Designing in the Browser
	Written for Handcraft.com by Martin Kool (@mrtnkl).

	Version 4.
	Recent change: Made stylesheet and mimetype checks case insensitive.

	http://livejs.com
	http://livejs.com/license (MIT)
	@livejs

	Include live.js#css to monitor css changes only.
	Include live.js#js to monitor js changes only.
	Include live.js#html to monitor html changes only.
	Mix and match to monitor a preferred combination such as live.js#html,css

	By default, just include live.js to monitor all css, js and html changes.

	Live.js can also be loaded as a bookmarklet. It is best to only use it for CSS then,
	as a page reload due to a change in html or css would not re-include the bookmarklet.
	To monitor CSS and be notified that it has loaded, include it as: live.js#css,notify
*/
(function () {
	if (document.body.hasAttribute("nolive")) return;
	let headers = { "Etag": 1, "Last-Modified": 1, "Content-Length": 1, "Content-Type": 1 },
		resources = {},
		pendingRequests = {},
		currentLinkElements = {},
		oldLinkElements = {},
		interval = 1000,
		loaded = false,
		active = { "html": 1, "css": 1, "js": 1 };
	
	const livenode = (function() {
		let meta = document.querySelector('meta[name="livenode"]');
		return meta ? meta.content : null;
	})();
	
	var __reloading = false;
	function doReload() {
		if (!__reloading) {
			document.location.reload();
			__reloading = true;
		}
	}

	const Live = {

		// performs a cycle per interval
		heartbeat: function () {
			if (document.body) {
				// make sure all resources are loaded on first activation
				if (!loaded) Live.loadresources();
				Live.checkForChanges();
			}
		},

		// loads all local css and js resources upon first activation
		loadresources: function () {

			// helper method to assert if a given url is local
			function isLocal(url) {
				let loc = document.location,
					reg = new RegExp("^\\.|^\/(?!\/)|^[\\w]((?!://).)*$|" + loc.protocol + "//" + loc.host);
				return url.match(reg);
			}

			// gather all resources
			let uris = [];

			// track local js urls
			if (active.js) for (let script of document.getElementsByTagName("script")) {
				let src = script.getAttribute("src");
				if (src && isLocal(src)) uris.push(src);
				if (src && src.match(/\blive.js#/)) {
					for (let type in active) active[type] = src.match("[#,|]" + type) != null
					if (src.match("notify")) alert("Live.js is loaded.");
				}
			}
			
			if (active.html) uris.push(document.location.href);

			// track local css urls
			if (active.css) for (let link of document.getElementsByTagName("link")) {
				let rel = link.getAttribute("rel"), href = link.getAttribute("href", 2);
				if (href && rel && rel.match(new RegExp("stylesheet", "i")) && isLocal(href)) {
					uris.push(href);
					currentLinkElements[href] = link;
				}
			}

			// initialize the resources info
			for (let url of uris) {
				Live.getHead(url, function (url, info) {
					resources[url] = info;
				});
			}

			// add rule for morphing between old and new css files
			let head = document.getElementsByTagName("head")[0],
				style = document.createElement("style"),
				rule = "transition: all .3s ease-out;"
			let css = [".livejs-loading * { ", rule, " -webkit-", rule, "-moz-", rule, "-o-", rule, "}"].join('');
			style.setAttribute("type", "text/css");
			head.appendChild(style);
			style.styleSheet ? style.styleSheet.cssText = css : style.appendChild(document.createTextNode(css));

			// yep
			loaded = true;
		},

		// check all tracking resources for changes
		checkForChanges: function () {
			for (let url in resources) {
				if (pendingRequests[url]) continue;

				Live.getHead(url, function (url, newInfo) {
					let oldInfo = resources[url],
						hasChanged = false;
					let contentType = newInfo["Content-Type"];
					// bothers me: when re-generating JS from Haxe/etc., file is 0 bytes for a moment
					if (contentType && contentType.includes("javascript") && newInfo["Content-Length"] == "0") return;
					resources[url] = newInfo;
					// this was in a loop before but it shouldn't be
					if (!contentType) return;
					//
					for (let header in oldInfo) {
						// do verification based on the header type
						let oldValue = oldInfo[header],
							newValue = newInfo[header];
						switch (header.toLowerCase()) {
							case "etag":
								if (!newValue) break;
								// fall through to default
							default:
								hasChanged = oldValue != newValue;
								break;
						}
						// if changed, act
						if (hasChanged) {
							Live.refreshResource(url, contentType);
							break;
						}
					}
				});
			}
		},

		// act upon a changed url of certain content type
		refreshResource: function (url, type) {
			switch (type.toLowerCase()) {
				// css files can be reloaded dynamically by replacing the link element
				case "text/css": {
					let link = currentLinkElements[url],
						html = document.body.parentNode,
						head = link.parentNode,
						next = link.nextSibling,
						newLink = document.createElement("link");

					html.className = html.className.replace(/\s*livejs\-loading/gi, '') + ' livejs-loading';
					newLink.setAttribute("type", "text/css");
					newLink.setAttribute("rel", "stylesheet");
					newLink.setAttribute("href", url + "?now=" + new Date() * 1);
					next ? head.insertBefore(newLink, next) : head.appendChild(newLink);
					currentLinkElements[url] = newLink;
					oldLinkElements[url] = link;

					// schedule removal of the old link
					Live.removeoldLinkElements();
					break;
				}
				case "text/html": { // check if an html resource is our current url, then reload
					// +y: do not consider index.html#a to be different from index.html#b:
					function hashless(url) {
						let p = url.indexOf("#");
						if (p >= 0) url = url.substring(0, p);
						return url;
					}
					if (hashless(url) != hashless(document.location.href)) break;
					
					if (livenode == null || !document.querySelector(livenode)) { // classic reload
						doReload();
						break;
					}
					
					// +y: if live-refresh node is known, replace its contents instead of reloading the page:
					let xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XmlHttp");
					xhr.open("GET", url, true);
					xhr.onreadystatechange = function () {
						if (xhr.readyState == 4) {
							let html = xhr.responseText;
							if (!html) return;
							let parser = new DOMParser();
							let next = parser.parseFromString(html, "text/html");
							let node0 = document.querySelector(livenode);
							let node1 = next.querySelector(livenode);
							if (window.live_pre) window.live_pre();
							node0.innerHTML = node1.innerHTML;
							// rerun inline scripts, else they won't work:
							let scripts = node1.querySelectorAll("script");
							for (let script of scripts) {
								if (!script.innerHTML) return;
								let copy = document.createElement("script");
								copy.innerHTML = script.innerHTML;
								document.head.appendChild(copy);
								setTimeout(() => copy.parentElement.removeChild(copy));
							}
							if (window.live_post) window.live_post();
							if (window.dotpage_nav) {
								window.liveHTML = html.split("<!--<doc-->")[1].split("<!--doc>-->")[0];
								let nav = document.querySelector("#navigation");
								if (nav) nav.innerHTML = "";
								window.dotpage_nav();
							}
						}
					}
					xhr.send();
					break;
				}
				case "text/javascript":
				case "application/javascript":
				case "application/x-javascript": {
					// local javascript changes cause a reload as well
					doReload();
					break;
				}
			}
		},

		// removes the old stylesheet rules only once the new one has finished loading
		removeoldLinkElements: function () {
			let pending = 0;
			for (let url in oldLinkElements) {
				// if this sheet has any cssRules, delete the old link
				try {
					let link = currentLinkElements[url],
						oldLink = oldLinkElements[url],
						html = document.body.parentNode,
						sheet = link.sheet || link.styleSheet,
						rules = sheet.rules || sheet.cssRules;
					if (rules.length >= 0) {
						oldLink.parentNode.removeChild(oldLink);
						delete oldLinkElements[url];
						setTimeout(function () {
							html.className = html.className.replace(/\s*livejs\-loading/gi, '');
						}, 100);
					}
				} catch (e) {
					pending++;
				}
				if (pending) setTimeout(Live.removeoldLinkElements, 50);
			}
		},

		// performs a HEAD request and passes the header info to the given callback
		getHead: function (url, callback) {
			pendingRequests[url] = true;
			let xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XmlHttp");
			xhr.open("HEAD", url, true);
			xhr.onreadystatechange = function () {
				delete pendingRequests[url];
				if (xhr.readyState == 4 && xhr.status != 304) {
					xhr.getAllResponseHeaders();
					let info = {};
					for (let h in headers) {
						let value = xhr.getResponseHeader(h);
						// adjust the simple Etag variant to match on its significant part
						if (h.toLowerCase() == "etag" && value) value = value.replace(/^W\//, '');
						if (h.toLowerCase() == "content-type" && value) value = value.replace(/^(.*?);.*?$/i, "$1");
						info[h] = value;
					}
					callback(url, info);
				}
			}
			xhr.send();
		}
	};

	// start listening
	if (document.location.protocol != "file:") {
		if (!window.liveJsLoaded) {
			setInterval(Live.heartbeat, interval);
			window.liveJsLoaded = true;
			console.log("live OK! Livenode is", livenode);
		} else {
			console.log("live already present!", livenode);
		}
	}
	else if (window.console) {
		console.log("Live.js doesn't support the file protocol. It needs http.");
	}
})();