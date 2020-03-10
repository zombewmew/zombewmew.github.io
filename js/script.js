function closeModal(){
    document.getElementById("myModal").style.display = "none";
}

$(function () {
    /* Modal box */
    var modal = document.getElementById("myModal");
    var list = document.getElementsByClassName("item-list");

    for(var i = 0; i < list.length; i++){
        list[i].addEventListener("click", openModal);
    }

    function openModal(){
        modal.style.display = "block";
    }
    
    window.onclick = function(event) {
        if (event.target == modal) {
            modal.style.display = "none";
        }
    }
 
    /* Request validation */
    $("input#email, input#name").on("change", function () {
        var id = $(this).attr('id');
        var val = $(this).val();

        if (id == "email") {
            let regexp = /^([a-zA-Z0-9_.-])+@([a-zA-Z0-9_.-])+\.([a-zA-Z])+([a-zA-Z])+/;

            if (val != '' && regexp.test(val)) {
                $(this).removeClass('error').addClass('valid').tooltip('dispose');
            }
            else {
                $(this).removeClass('valid').addClass('error').tooltip('show');
            }

        } else if (id == "name") {
            let regexp = /^[a-zA-Zёа-яЁА-Я- ]+$/;

            if (val != '' && regexp.test(val)) {
                $(this).removeClass('error').addClass('valid').tooltip('dispose');
            }
            else {
                $(this).removeClass('valid').addClass('error').tooltip('show');
            }
        }
    });

    $('#request').on("submit", function (e) {

        e.preventDefault();

        if ($('.valid').length == 2 && $('#checkbox').prop('checked') && $('#select').val() !== '') {
            alert("Заявка принята!")
        }
        else {
            //alert("Заполните все поля")
            return false;
        }
    });

});
