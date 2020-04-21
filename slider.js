function plusSlides(n) {
    slideIndex += n
    showSlides();
}

function currentSlide(n) {
    showSlides(slideIndex = n);
}

var progressCheck = 0;
var idSlider = 0;
var slideIndex = 0;
var dots = document.getElementsByClassName("dots__item");
var progress = document.querySelectorAll('.progress');

var r = 0; //check starting slider's interval
showSlides(slideIndex);

function showSlides(slide) {
    if (r != 0) {
        clearInterval(r);
    }

    var slides = document.getElementsByClassName("carousel-slide");
    
    for (var i = 0; i < slides.length; i++) {
        slides[i].style.display = "none"; 
        dots[i].classList.remove("active");
        progress[i].style.width = 0;
    }
    
    if (slideIndex >= slides.length) {
        slideIndex = 0
    } 
    if (slideIndex < 0) {
        slideIndex = slides.length - 1
    }

    slides[slideIndex].style.display = "block"; 
    dots[slideIndex].classList.add("active");

    playProgress(slideIndex);

    r = setTimeout(function() { showSlides(slideIndex++); }, 15000)
}

function playProgress(n) {
    clearInterval(idSlider);
    progressCheck = 1;
    var width = 1;
    idSlider = setInterval(frame, 10);
    function frame() {
        
        if (width >= 100) {
            clearInterval(idSlider);
            progressCheck = 0;
        } else {
            width += 100 / 1500;
            progress[n].style.width = width + "%";
        }
    }
}