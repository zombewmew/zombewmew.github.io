var modal = document.getElementById("modal");
var modalImg = document.getElementById("image-content");

window.onload = function() {
    var anchors = document.querySelectorAll('.spaceship-block img');
    for(var i = 0; i < anchors.length; i++) {
        var anchor = anchors[i];
        anchor.onclick = function() {
            modal.style.display = "flex";
            modalImg.src = this.src;
        }
    }
}

var closeButton = document.getElementsByClassName("close")[0];
closeButton.onclick = function() { 
    modal.style.display = "none";
}