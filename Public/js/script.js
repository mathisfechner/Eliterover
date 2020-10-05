function answer(path, divid) {
	fetch(path, {method: "post"}).then(function(response) {
		document.getElementById(divid).animate([{height: document.getElementById(divid).scrollHeight},{height: 0, opacity: 0, padding: 0, margin: 0}], {duration: 200, iterations: 1, fill: "forwards"}).finished.then(function() {document.getElementById(divid).remove()})
	});
}