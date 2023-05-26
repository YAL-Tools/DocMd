(function() {
	var night = document.getElementById("night");
	var path = "docmd night mode";
	var ls = window.localStorage;
	var dark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
	if (ls) {
		var item = ls.getItem(path);
		night.checked = item ? item == "true" : dark;
		night.onchange = function(_) {
			ls.setItem(path, "" + night.checked);
		};
	} else night.checked = dark;
})();