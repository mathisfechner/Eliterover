acceptCookie()

function acceptCookie() {
	var cookieButton = document.getElementById("cookie");
	cookieButton.addEventListener("click",function() {
		var request = new XMLHttpRequest();
		request.open("POST","accept/cookies");
		request.send();
	});
}