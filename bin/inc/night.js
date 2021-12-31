(function() {
	var night = document.getElementById("night");
	var path = "docmd night mode";
	var ls = window.localStorage;
	if (ls) {
		night.checked = ls.getItem(path) == "true";
		night.onchange = function(_) {
			ls.setItem(path, "" + night.checked);
		};
	}
})();