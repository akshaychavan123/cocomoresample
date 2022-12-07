// File inputs must have class: 'cropper' and an id <someIdName>
// Hidden field on Modal to store the image temporarily must have an id #croppedImageTempStore
// For image previw Image tag must be present within the input ID and must have 'preview' class
// On cropper submit button in the modal id:'replaceCroppedImage' must be present.
// use this modal only one on each page app/views/admin/brand_settings/_new.html.erb
var isImageCropped;
var inputFileButtonId;

function cropImage(inputId) {
  $("#replaceCroppedImage").on("click", function () {
    var cropper = $("#croppableImage")[$("#croppableImage").length - 1].cropper;
    if (cropper != undefined && cropper != null) {
      var imageFormat = cropper.url.split(":")[1].split(";")[0];
      var croppedBase64 = cropper.getCroppedCanvas(imageFormat.match(/.(jpg|jpeg)$/i)? {fillColor: '#ffffff'} : "").toDataURL(cropper.url.split(":")[1].split(";")[0]);
      var attachmentId =
        $("#" + inputFileButtonId).attr("cropped-image-temp-store-id") 
      $(attachmentId).val(croppedBase64);

      //Image preview//
      if (
        $("#" + inputFileButtonId)
          .parent()
          .find("img.preview").length > 0
      ) {
        $("#" + inputFileButtonId)
          .parent()
          .find("img.preview")
          .replaceWith(`<img class='preview' src=${croppedBase64}>`);
      } else {
        $("#" + inputFileButtonId)
          .parent()
          .find("span")
          .replaceWith(`<img class='preview' src=${croppedBase64}>`);
      }

      isImageCropped = true;
      if(document.getElementById("productCropper")){
        $('#productCropper').css('display','none');
      }
      if(document.getElementById("ex1")){
        $('#ex1 a[rel="modal:close"]').click();
      }

      cropper.destroy();
      cropper = null;
    }
  });
}
function handleDrop(e) {
  let dt = e.dataTransfer
  let files = dt.files
  var reader = new FileReader();
  reader.onload = function (e) {
    $("#croppableImage").attr("src", e.target.result);
  };
  reader.readAsDataURL(files[files.length - 1]);
  if(document.getElementById("bulkuploadModal")){
    $("#bulkuploadModal").css('display','none')
  }
  $("#productCropper").css("display","block");

  setTimeout(function () {
    const image = $("#croppableImage")[$("#croppableImage").length - 1];
    new Cropper(image, {
      aspectRatio: 1 / 1,
      crop(event) {},
      zoomable: true,
    });
    cropImage(inputFileButtonId);
  }, 1000);
}
function selectImage(event){
  currentPage = 1;
  $("#searchImage").val('');
  function toDataUrl(url, callback) {
    var xhr = new XMLHttpRequest();
    xhr.onload = function() {
      var reader = new FileReader();
      reader.onloadend = function() {
        callback(reader.result);
      }
      reader.readAsDataURL(xhr.response);
    };
    xhr.open('GET', url);
    xhr.responseType = 'blob';
    xhr.send();
  }
  if($(".selectedImage").attr("src")){
    toDataUrl($(".selectedImage").attr("src"), function(myBase64) {
      $("#croppableImage").attr("src",myBase64);
    });
    if(document.getElementById("bulkuploadModal")){
      $("#bulkuploadModal").css('display','none')
    }
    $("#productCropper").css("display","block");
    setTimeout(function () {
      const image = $("#croppableImage")[$("#croppableImage").length - 1];
      new Cropper(image, {
        aspectRatio: 1 / 1,
        crop(event) {},
        zoomable: true,
      });
      cropImage(inputFileButtonId);
    }, 1000);
  }
}
function initCropper() {
  $(document).on("click", ".image-container11 img", function (e) {
    $(".image-container11 img").removeClass("selectedImage");
    $(".image-container11 .selectedicon").removeClass("showselectedicon");
    $(this).addClass("selectedImage")
    $(".image-container11 .selectedImage").next().addClass("showselectedicon");
    $("#selectImageButton").removeClass("disableButton")
  })
  $(document).on("change", ".cropper", function (e) {
    var inputId = e.target.id;
    if(inputId !== 'file1'){
      inputFileButtonId = inputId;
    }


    var reader = new FileReader();
    reader.onload = function (e) {
      $("#croppableImage").attr("src", e.target.result);
    };
    reader.readAsDataURL(this.files[this.files.length - 1]);

    if(document.getElementById("bulkuploadModal")){
      $("#bulkuploadModal").css('display','none')
    }
    if(document.getElementById("productCropper")){
      $("#productCropper").css("display","block");
    }
    if(document.getElementById("ex1")){
      $("#ex1").modal({
        escapeClose: false,
        clickClose: false,
      });
    }

    setTimeout(function () {
      const image = $("#croppableImage")[$("#croppableImage").length - 1];
      new Cropper(image, {
        aspectRatio: e.currentTarget.id=== 'brandSettingLogo'? NaN :1/1,
        crop(event) {},
        zoomable: true,
      });
      cropImage(inputFileButtonId);
    }, 1000);
  });
}

$(document).on("click", ".close-modal", function (e) {
  var cropper = $("#croppableImage")[$("#croppableImage").length - 1].cropper;

  // Remove file if the image is not cropped
  if (!isImageCropped) {
    document.getElementById(`${inputFileButtonId}`).value = "";
    cropper.destroy();
    cropper = null;
  }

  isImageCropped = false;
});

$(document).ready(function () {
  initCropper();
});

$(document).on("click", "#zoomin", function (e) {
  var cropper = $("#croppableImage")[$("#croppableImage").length - 1].cropper;
  cropper.zoom(0.1);
});
$(document).on("click", "#zoomout", function (e) {
  var cropper = $("#croppableImage")[$("#croppableImage").length - 1].cropper;
  cropper.zoom(-0.1);
});

document.addEventListener("DOMContentLoaded", function () {
  $(".custom-file-inputproduct").siblings('label').css("visibility","hidden")
  $(".custom-file-inputproduct").on("click",function(event){
    var inputId = event.target.id;
    inputFileButtonId = inputId;
    event.preventDefault();
    $("#bulkuploadModal").css("display","block")
    getImages("",1);
  })
  function onChangeElement(qSelector, cb) {
    const targetNode = document.querySelector(qSelector);
    if(targetNode){
      const config = { attributes: true, childList: true, subtree: true };
      const callback = function(mutationsList, observer) {
        cb($(qSelector))
      };
      const observer = new MutationObserver(callback);
      observer.observe(targetNode, config);
    }else {
      console.error("onChangeElement: Invalid Selector")
    }
  }
  $("#edit_catalogue .has_many_container.attachments .button.has_many_add").on("click",()=>{
    setTimeout(() => {
      $(".custom-file-inputproduct").off("click")
      $(".custom-file-inputproduct").on("click",function(event){
        var inputId = event.target.id;
        inputFileButtonId = inputId;
        event.preventDefault();
        $("#bulkuploadModal").css("display","block")
        $("#bulk-image-list-conaioner").html("")
        getImages("",1);
      })
    }, 500);

  })
  $("#new_catalogue .has_many_container.attachments .button.has_many_add").on("click",()=>{
    setTimeout(() => {
      $(".custom-file-inputproduct").off("click")
      $(".custom-file-inputproduct").on("click",function(event){
        var inputId = event.target.id;
        inputFileButtonId = inputId;
        event.preventDefault();
        $("#bulkuploadModal").css("display","block")
        $("#bulk-image-list-conaioner").html("")
        getImages("",1);
      })
    }, 500);

  })
  $("#new_catalogue .has_many_container.catalogue_variants .button.has_many_add").on("click",()=>{
    setTimeout(() => {
      $("#new_catalogue .has_many_container.attachments .button.has_many_add").on("click",()=>{
        setTimeout(() => {
          $(".custom-file-inputproduct").off("click")
          $(".custom-file-inputproduct").on("click",function(event){
            var inputId = event.target.id;
            inputFileButtonId = inputId;
            event.preventDefault();
            $("#bulkuploadModal").css("display","block")
            $("#bulk-image-list-conaioner").html("")
            getImages("",1);
          })
        }, 500);

      })
    }, 500);
  })

  $("#edit_catalogue .has_many_container.catalogue_variants .button.has_many_add").on("click",()=>{
    setTimeout(() => {
      $("#edit_catalogue .has_many_container.attachments .button.has_many_add").on("click",()=>{
        setTimeout(() => {
          $(".custom-file-inputproduct").off("click")
          $(".custom-file-inputproduct").on("click",function(event){
            var inputId = event.target.id;
            inputFileButtonId = inputId;
            event.preventDefault();
            $("#bulkuploadModal").css("display","block")
            $("#bulk-image-list-conaioner").html("")
            getImages("",1);
          })
        }, 500);

      })
    }, 500);
  })
  //  onChangeElement('#edit_catalogue,#new_catalogue', function(jqueryElement){
  //   $(".custom-file-inputproduct").siblings('label').css("visibility","hidden")
  //   $(".custom-file-inputproduct").on("click",function(event){
  //     var inputId = event.target.id;
  //     inputFileButtonId = inputId;
  //     event.preventDefault();
  //     $("#bulkuploadModal").css("display","block")
  //     // getImages("",1);
  //   })
  // })

  $("#exampleModalLabel").on("click",()=>{
    $("#productCropper").css("display","none");
    $("#bulkuploadModal").css("display","block")
    var cropper = $("#croppableImage")[$("#croppableImage").length - 1].cropper;

    // Remove file if the image is not cropped
    if (!isImageCropped) {
      document.getElementById(`${inputFileButtonId}`).value = "";
      cropper.destroy();
      cropper = null;
    }

    isImageCropped = false;
  })
})
function closeCroperDialog(){
  $("#productCropper").css("display","none");
  var cropper = $("#croppableImage")[$("#croppableImage").length - 1].cropper;

  // Remove file if the image is not cropped
  if (!isImageCropped) {
    document.getElementById(`${inputFileButtonId}`).value = "";
    cropper.destroy();
    cropper = null;
  }

  isImageCropped = false;
}
