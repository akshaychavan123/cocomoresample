$(function () {
  $(document).off("click", ".clear_filters_btn");
  $(".clear_filters_btn").attr("href", "?commit=clear_filters");
});

jQuery(function () {
  //We can remove this code if we get issues in loading icon on ckeditor
  CKEDITOR.on("instanceReady", function () {
    $(".cke_button_icon").removeAttr("style");
    $(".cke_button_icon").attr(
      "style",
      "background-image: url('/assets/ckeditor/plugins/icons.png?t=H5SC') !important"
    );
  });

  $(".on_sale").each(function () {
    update_sale_field($(this));
  });

  $(".brand_setting_country").change(function () {
    if ($(this).val() == "uk") {
      $("#brand_setting_currency_type").val("£");
      $('#brand_setting_address_state_id_input').hide();
    } else if ($(this).val() == "india") {
      $("#brand_setting_currency_type").val("INR");
      $('#brand_setting_address_state_id_input').show();
    }
  });

  $(document).ready(function () {
    if (window.location.pathname.includes("/admin/brand_settings/")) {
      var countryCode = document.getElementById("brand_setting_country").value;
      if (countryCode == "uk") {
        addCountryCodeSpan("+44");
      } else if (countryCode == "india") {
        addCountryCodeSpan("+91");
      }
    }
  });

  $("#brand_setting_country").change(function () {
    if ($(this).val() == "uk") {
      addCountryCodeSpan("+44");
    } else if ($(this).val() == "india") {
      addCountryCodeSpan("+91");
    }
  });

  function addCountryCodeSpan(countryCode) {
    // For phone_number
    var numberInput = document.getElementById("brand_setting_phone_number");
    var html = numberInput.outerHTML;
    var number = numberInput.value;
    $("#brand_setting_phone_number_input span").remove();
    numberInput.outerHTML =
      "<div class='brand-setting-customer-no'><span>" +
      countryCode +
      "</span>" +
      html +
      "</div>";
    document.getElementById("brand_setting_phone_number").value = number;

    // For whatsapp_number
    var numInput = document.getElementById("brand_setting_whatsapp_number");
    var html = numInput.outerHTML;
    var number = numInput.value;
    $("#brand_setting_whatsapp_number_input div.brand-setting-customer-no").remove();
    numInput.outerHTML =
      "<div class='brand-setting-customer-no'><span>" +
      countryCode +
      "</span>" +
      html +
      "</div>";
    var a = "<div class='brand-setting-customer-no'><span>" +
      countryCode +
      "</span>" +
      html +
      "</div>";

    if(document.getElementById("brand_setting_whatsapp_number")){
      document.getElementById("brand_setting_whatsapp_number").value = number;
    } else {
      if($("#brand_setting_whatsapp_number_input p.inline-errors").length > 0){
        const error = $("#brand_setting_whatsapp_number_input p.inline-errors").text();
        $("#brand_setting_whatsapp_number_input p.inline-errors").remove();
        $("#brand_setting_whatsapp_number_input").append(a)
        $("#brand_setting_whatsapp_number_input").append(`<p class="inline-errors">${error}</p>`)
      } else {
        $("#brand_setting_whatsapp_number_input").append(a)
      }

    }

    // $("#brand_setting_whatsapp_number_input label").append("<span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Add 10 digit what's app number where you want to receive messages</span></i></span>")
  }

  $(".hint_web_banner_image").change(function () {
    img_src = "/assets/banner_position_" + $(this).val() + ".png";
    $(".banner_inline_hint").attr("src", img_src);
  });

  $(document).on("change", ".on_sale, input[name*='on_sale']", function () {
    update_sale_field($(this));
  });

  $(document).on(
    "input",
    ".sale_price, .product_price, input[name*='sale_price']",
    function () {
      element = $(this);
      if ($(this).hasClass("product_price")) {
        element = $(this).closest("ol").find(".sale_price");
      }

      discount_element =
        $(this).closest("ol").find(".discount").length < 1
          ? element.closest("ul").find("input[name=discount]")
          : $(this).closest("ol").find(".discount");
      price =
        $(this).closest("ol").find(".product_price").length < 1
          ? element.closest("ul").find("input[name=price]").val()
          : element.closest("ol").find(".product_price").val();
      if (element.val() != "") {
        discount_element.val(
          (((price - element.val()) / price) * 100).toFixed(2)
        );
      } else {
        discount_element.val("");
      }
    }
  );

  $(".pv_panel").append(
    '<span class="toggle_icon"><input type="checkbox" name="check_status" class="check_status"></span>'
  );
  var variant_panels = $(".pv_panel");

  variant_panels.each(function (index, panel) {
    if ($(panel).find("div.field_with_errors").length > 0) {
      $(panel).css("height", "unset");
    } else {
      $(panel).css("height", "90px");
    }
  });

  $(document).on("click", ".toggle_icon", function () {
    var check = $(this).find("input[name='check_status']").prop("checked");
    if (check) {
      $(this).parent().css("height", "unset");
    } else {
      $(this).parent().css("height", "90px");
    }
  });

  $(document).on("click", ".inline-hints", function () {
    var src = $(this).find("img").attr("src");
    if (src != null) {
      ActiveAdmin.modal_dialog("Image");
      $(".ui-dialog-title").hide();
      $(".ui-button.ui-corner-all.ui-widget").each(function () {
        if ($(this).text() == "OK") {
          $(this).hide();
        }
      });
      $("#dialog_confirm").prepend('<img id="pImage" />');
      $(".ui-dialog").css("z-index", "9");
      $("#pImage").attr("src", src);
      $("body").append('<div class="backdrop"></div>');
      $(".ui-dialog-buttonset").css("margin-top", "15px");
      $(".ui-button.ui-corner-all.ui-widget").on("click", function () {
        $("body").find(".backdrop").remove();
      });
      $("#pImage")
        .parent()
        .closest(".active_admin_dialog")
        .css({ width: "600px", left: "0px", right: "0", margin: "0 auto" });
    }
  });
});

$(document).on("click", ".catalogue_variants a", function (evt) {
  setTimeout(function () {
    $(".pv_panel")
      .last()
      .append(
        '<span class="toggle_icon"><input type="checkbox" name="check_status" class="check_status"></span>'
      );
  }, 200);
});

$(document).on("click", ".catalogue_variants a", function (evt) {
  $(".catalogue_subscriptions").hide();
});

$(document).on("click", ".catalogue_subscriptions a", function (evt) {
  $(".catalogue_variants").hide();
});

function update_sale_field(element) {
  discount_field =
    element.closest("ol").find(".discount").length < 1
      ? element.closest("ul").find("input[name=discount]")
      : element.closest("ol").find(".discount");
  sale_price_field =
    element.closest("ol").find(".sale_price").length < 1
      ? element.closest("ul").find("input[name=sale_price]")
      : element.closest("ol").find(".sale_price");
  if (element.is(":checked")) sale_price_field.attr("readonly", false);
  else {
    sale_price_field.attr("readonly", true).val("");
    discount_field.val("");
  }
}

$(document).on("change", ".select_variant", function (evt) {
  if ($(this).val())
    ind = $(this).data("select2-id").split("attributes_")[1].split("_")[0];

  {
    return $.ajax("/admin/variants/" + $(this).val() + "/get_attributes", {
      type: "GET",
      dataType: "html",
      data: {
        variant_id: $(this).val(),
      },
      error: function (jqXHR, textStatus, errorThrown) {
        return console.log("AJAX Error: " + textStatus);
      },
      success: function (data, textStatus, jqXHR) {
        // Clear all options from course select
        $(
          `select#product_product_variants_attributes_${ind}_variant_property_id option`
        ).remove();
        //put in a empty default line
        var row =
          '<option value="' + "" + '">' + "Variant Attribute" + "</option>";
        $(row).appendTo(
          `select#product_product_variants_attributes_${ind}_variant_property_id`
        );
        // Fill course select
        data = JSON.parse(data);
        $.each(data["variant_properties"], function (i, j) {
          row = '<option value="' + j.id + '">' + j.name + "</option>";
          $(row).appendTo(
            `select#product_product_variants_attributes_${ind}_variant_property_id`
          );
        });
      },
    });
  }
});

$(document).on("change", ".configuration_type", function () {
  var config_type = $(this).val();

  if (config_type == "shiprocket") {
    $(".shiprocket_fields").closest("li").show();
    $(".bulkgate_fields").closest("li").hide();
    $(".api_key").closest("li").hide();
    $(".logistic_keys").closest("li").hide();
  } else if (config_type == "razorpay" || config_type == "stripe") {
    $(".api_key").closest("li").show();
    $(".bulkgate_fields").closest("li").hide();
    $(".shiprocket_fields").closest("li").hide();
    $(".logistic_keys").closest("li").hide();
  } else if (config_type == "bulkgate_sms") {
    $(".shiprocket_fields").closest("li").hide();
    $(".bulkgate_fields").closest("li").show();
    $(".api_key").closest("li").hide();
    $(".logistic_keys").closest("li").hide();
  } else if (config_type == "525k") {
    $(".logistic_keys").closest("li").show();
    $(".api_key").closest("li").hide();
    $(".shiprocket_fields").closest("li").hide();
    $(".bulkgate_fields").closest("li").hide();
  }
});

$(document).ready(function () {
  $.ajax({
    type: "GET",
    url: "/store_profile/brand_settings/change_site_title",
  });

  var config_type = $(".configuration_type").val();
  if (config_type == "shiprocket") {
    $(".shiprocket_fields").closest("li").show();
    $(".bulkgate_fields").closest("li").hide();
    $(".api_key").closest("li").hide();
    $(".logistic_keys").closest("li").hide();
  } else if (config_type == "razorpay" || config_type == "stripe") {
    $(".api_key").closest("li").show();
    $(".bulkgate_fields").closest("li").hide();
    $(".shiprocket_fields").closest("li").hide();
    $(".logistic_keys").closest("li").hide();
  } else if (config_type == "bulkgate_sms") {
    $(".shiprocket_fields").closest("li").hide();
    $(".bulkgate_fields").closest("li").show();
    $(".api_key").closest("li").hide();
    $(".logistic_keys").closest("li").hide();
  } else if (config_type == "525k") {
    $(".shiprocket_fields").closest("li").hide();
    $(".api_key").closest("li").hide();
    $(".bulkgate_fields").closest("li").hide();
    $(".logistic_keys").closest("li").show();
  } else {
    $(".shiprocket_fields").closest("li").hide();
    $(".bulkgate_fields").closest("li").hide();
    $(".api_key").closest("li").hide();
    $(".logistic_keys").closest("li").hide();
  }

  var nested_menu = $(".nested_menu");
  nested_menu.each(function (index, menu) {
    var url = window.location;
    if (url.href.includes(menu.href)) {
      $(menu).css("background-color", "#ffffff");
      $(menu).closest(".menu").parent().addClass("open");
      $(menu).closest(".menu").parent().parent().parent().addClass("open");
      return false;
    }
  });

  $(".flashes .flash").fadeOut(6000);

  if ($(".popular").length > 0) {
    if ($(".scope.all.selected").length > 0) {
      $(".popular")
        .find("a")
        .attr("href", "/admin/products?order=sold_desc&scope=popular");
      $(".scope.latest").find("a").attr("href", "/admin/products?scope=latest");
    } else if ($(".scope.latest.selected").length > 0) {
      $(".popular")
        .find("a")
        .attr("href", "/admin/products?order=sold_desc&scope=popular");
      $(".scope.all").find("a").attr("href", "/admin/products?scope=all");
    } else if ($(".scope.popular.selected").length > 0) {
      $(".scope.all").find("a").attr("href", "/admin/products?scope=all");
      $(".scope.latest").find("a").attr("href", "/admin/products?scope=latest");
    } else {
      $(".popular")
        .find("a")
        .attr("href", "/admin/products?order=sold_desc&scope=popular");
    }
  }
});

$(document).on("change", ".url_type, input[name*='url_type']", function () {
  update_url_type_field($(this));
});

function update_url_type_field(element) {
  url_id2 = element.parent().parent().find(".url_id2");
  url_id1 = element.parent().parent().find(".url_id1");
  if (element.val() === "product") {
    url_id2.attr("disabled", true);
    url_id1.attr("disabled", false);
    url_id1.parent().show();
    url_id2.parent().hide();
  } else if (element.val() === "category") {
    url_id1.attr("disabled", true);
    url_id2.attr("disabled", false);
    url_id1.parent().hide();
    url_id2.parent().show();
  } else if (element.val() === "") {
    url_id1.parent().hide();
    url_id2.parent().hide();
    url_id2.attr("disabled", true);
    url_id1.attr("disabled", true);
  }
}

$(document).ready(function () {
  $(".url_type").each(function () {
    var url_type = $(this).val();
    url_id2 = $(this).parent().parent().find(".url_id2");
    url_id1 = $(this).parent().parent().find(".url_id1");
    if (url_type == "product") {
      url_id1.parent().show();
      url_id1.attr("disabled", false);
      url_id2.parent().hide();
    } else if (url_type == "category") {
      url_id1.parent().hide();
      url_id2.parent().show();
      url_id2.attr("disabled", false);
    } else {
      url_id1.parent().hide();
      url_id2.parent().hide();
      url_id1.attr("disabled", true);
      url_id2.attr("disabled", true);
    }
  });
  if ($(".action_item a").length > 0) {
    if ($(".action_item a").text().includes("New Qr Code")) {
      $(".action_item a").text("Generate QR Code");
    }
  }

  $("select[name*='morning_slot']").each(function (key, element) {
    var value = $(element).attr("value");
    $(element)
      .children()
      .each(function (option_index, option_element) {
        var option_value = $(option_element).val();
        if (value.includes(option_value)) {
          $(option_element).attr("selected", "selected");
          $(option_element).show();
        }
        if (
          $(".remove-select2-hidden-accessible").hasClass(
            "select2-hidden-accessible"
          )
        ) {
          $(".remove-select2-hidden-accessible").select2("destroy");
        }
      });
  });

  $("select[name*='evening_slot']").each(function (key, element) {
    var value = $(element).attr("value");
    $(element)
      .children()
      .each(function (option_index, option_element) {
        var option_value = $(option_element).val();
        if (value.includes(option_value)) {
          $(option_element).attr("selected", "selected");
        }
        if (
          $(".remove-select2-hidden-accessible").hasClass(
            "select2-hidden-accessible"
          )
        ) {
          $(".remove-select2-hidden-accessible").select2("destroy");
        }
      });
  });
});

$(document).ready(function () {
  if (window.location.pathname.includes("/admin/onboarding_steps")) {
    $(".onboarding_menu").css("background-color", "#ffffff");
    $(".onboarding_menu").closest(".menu").parent().addClass("open");
    $(".onboarding_menu")
      .closest(".menu")
      .parent()
      .parent()
      .parent()
      .addClass("open");
  }
});

document.addEventListener("DOMContentLoaded", function (event) {
  let div = document.createElement("div");
  div.classList.add("borderlist");
  document.querySelector(".preview-website").prepend(div); // Your code to run since DOM is loaded and ready
  $(".preview-website").hover(
    function () {
      $(".preview-external-link").addClass("preview-external-link-show");
    },
    function () {
      $(".preview-external-link").removeClass("preview-external-link-show");
    }
  );
});

document.addEventListener("DOMContentLoaded", function (event) {
  function insertAfter(newNode, existingNode) {
    existingNode.parentNode.insertBefore(newNode, existingNode.nextSibling);
  }
  if(document.getElementById("description_section")){
    var fragment = document.createDocumentFragment();
    fragment.appendChild(document.getElementById("description_section"));
    insertAfter(fragment, document.getElementById("title_bar")); // Your code to run since DOM is loaded and ready
  }

  if(document.getElementById("total_status_view")){
    // $("#main_content").css("background",'#eee')
    // $("#main_content").css("margin-left",'-25px')
    // $("#main_content").css("box-shadow",'none')
    var fragment = document.createDocumentFragment();
    fragment.appendChild(document.getElementById("total_status_view"));
    insertAfter(fragment, document.getElementById("title_bar")); // Your code to run since DOM is loaded and ready
  }
  if(document.getElementById("onboarding_step")){
    // $("#main_content").css("background",'#eee')
    // $("#main_content").css("margin-left",'-25px')
    // $("#main_content").css("box-shadow",'none')
    var fragment = document.createDocumentFragment();
    fragment.appendChild(document.getElementById("onboarding_step"));
    insertAfter(fragment, document.getElementById("total_status_view")); // Your code to run since DOM is loaded and ready
  }
  //


  // Append desired element to the fragment:

});

function htmlDecode(text) {
  var encoded = new DOMParser().parseFromString(text, "text/html");
  return encoded.documentElement.textContent;
}

$(document).on("click", ".btn_start", function (event) {
  trackAnalytics('welcome_cta_selected', null)
});

$(document).on("click", ".step_btn", function (event) {
  trackAnalytics('new_products_initiated', 'Dashboard')
});

$(document).on("click", ".new-products", function (event) {
  trackAnalytics('new_products_initiated', 'Navigation Panel')
});

$(document).on("click", ".customer-inbound-queries", function (event) {
  trackAnalytics('inobund_queries_viewed', null)
});

$(document).on("click", ".customer-reviews", function (event) {
  trackAnalytics('customer_reviews_viewed', null)
});

$(document).on("click", ".export-customer-list", function (event) {
  trackAnalytics('customer_list_exported', null)
});

$(document).on("click", ".onboarding-branding", function (event) {
  trackAnalytics('brand_settings_accessed', 'Dashboard')
});

$(document).on("click", ".brand-settings-nav", function (event) {
  trackAnalytics('brand_settings_accessed', 'Navigation Panel')
});

$(document).on("click", ".onboarding-email", function (event) {
  trackAnalytics('email_templates_accessed', 'Dashboard')
});

$(document).on("click", ".email-templates-nav", function (event) {
  trackAnalytics('brand_settings_accessed', 'Navigation Panel')
});

$(document).on("click", ".onboarding-app_banner", function (event) {
  trackAnalytics('app_banners_accessed', 'Dashboard')
});

$(document).on("click", ".app-banners-nav", function (event) {
  trackAnalytics('app_banners_accessed', 'Navigation Panel')
});

$(document).on("click", ".onboarding-web_banner", function (event) {
  trackAnalytics('web_banners_accessed', 'Dashboard')
});

$(document).on("click", ".web-banners-nav", function (event) {
  trackAnalytics('web_banners_accessed', 'Navigation Panel')
});

$(document).on("click", ".onboarding-variants", function (event) {
  trackAnalytics('variants_accessed', 'Dashboard')
});

$(document).on("click", ".variants-nav", function (event) {
  trackAnalytics('variants_accessed', 'Navigation Panel')
});

$(document).on("click", ".onboarding-brands", function (event) {
  trackAnalytics('brands_accessed', 'Dashboard')
});

$(document).on("click", ".brands-nav", function (event) {
  trackAnalytics('brands_accessed', 'Navigation Panel')
});

$(document).on("click", ".download-categories-sample-file", function (event) {
  trackAnalytics('categories_sample_downloaded', null)
});

$(document).on("click", ".onboarding-taxes", function (event) {
  trackAnalytics('taxes_accessed', 'Dashboard')
});

$(document).on("click", ".taxes-nav", function (event) {
  trackAnalytics('taxes_accessed', 'Navigation Panel')
});

$(document).on("click", ".onboarding-shipping", function (event) {
  trackAnalytics('shipping_charges_accessed', 'Dashboard')
});

$(document).on("click", ".shipping_charges-nav", function (event) {
  trackAnalytics('shipping_charges_accessed', 'Navigation Panel')
});

$(document).on("click", ".onboarding-third_party_services", function (event) {
  trackAnalytics('3rd_party_configuration_accessed', 'Dashboard')
});

$(document).on("click", ".partner_configurations-nav", function (event) {
  trackAnalytics('3rd_party_configuration_accessed', 'Navigation Panel')
});

function trackAnalytics(event, clicked_source) {
  $.ajax({
    type: "GET",
    url: "/onboarding/track_analytics",
    data : { 'event': event, 'clicked_source': clicked_source }
  });
}
$(document).ready(function () {
  $("#bulk_upload_submit_button span").html("Create Bulk Upload")
})

$(document).ready(function() {
  if ($('#brand_setting_country').val() != undefined && $('#brand_setting_country').val() != 'india'){
    $('#brand_setting_address_state_id_input').hide();
  }
});

$(document).ready(function () {
  $('.bulk-upload-multiple-file').on('change', function() {
    let totalFileSize = 0;
    for(let i=0;i<this.files.length;i++){
      totalFileSize += this.files[i].size;
    }
    const totalSIze = totalFileSize /  1024 / 1024;
    if(totalSIze > 47){
      $("#bulk_upload_submit_button").attr("disabled",true)
      $("#bulk_upload_error_msg").css("display","block")
    } else {
      $("#bulk_upload_submit_button").attr("disabled",false),
        $("#bulk_upload_error_msg").css("display","none")
    }
    console.log('This file size is: ' + this.files[0].size / 1024 / 1024 + "MiB");
  });
})

$(document).ready(function (){
  const templates = ['Minimal', 'Prime','Bold','Ultra','Essence']
  templates.forEach((template)=>{
    $(`#brand_setting_template_selection_input .choices-group .choice.template_selection_${template.toLowerCase()} label`)
      .append(`<p class="templates-inline-hints">
    <img class="banner_inline_hint" style="width:100%!important;height:220px;margin-left:10px" src="/assets/${template}${template === 'Minimal' ? '.png' : '.jpg'}" />
    <p>Preview</p>
    </p>`)
  })
  $(document).on("click", ".templates-inline-hints + p", function (event) {
    event.preventDefault();
    event.stopPropagation();
    var src = $(this).prev().find("img").attr("src");
    if (src != null) {
      ActiveAdmin.modal_dialog("Image");
      $(".ui-dialog-title").hide();
      $(".ui-button.ui-corner-all.ui-widget").each(function () {
        if ($(this).text() == "OK") {
          $(this).hide();
        }
      });
      $("#dialog_confirm").prepend('<img id="pImage" />');
      $(".ui-dialog").css("z-index", "9");
      $(".ui-dialog").css("position", "absolute");
      $(".ui-dialog").css("top", "20px");
      $(".ui-dialog-content").css("max-height","80vh")
      $(".ui-dialog-content").css("overflow","scroll")
      $("#pImage").attr("src", src);
      $("body").append('<div class="backdrop"></div>');
      $(".admin_namespace").css("overflow","hidden")
      $(".ui-dialog-buttonset").css("margin-top", "15px");
      $(".ui-button.ui-corner-all.ui-widget").on("click", function () {
        $("body").find(".backdrop").remove();
        $(".admin_namespace").css("overflow","auto")
      });

      $("#pImage")
        .parent()
        .closest(".active_admin_dialog")
        .css({ width: "600px", left: "0px", right: "0", margin: "0 auto" });
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  });

  const colorPelletes = [ {themeName: 'Sky',primaryColor:'#364F6B',secondaryColor:'#3FC1CB'},
    {themeName: 'Navy',primaryColor:'#011638',secondaryColor:'#FE5F55'},
    {themeName: 'Bonsai',primaryColor:'#4A6C6F',secondaryColor:'#7FB069'},
    {themeName: 'Forest',primaryColor:'#0B3C49',secondaryColor:'#BE7C4D'},
    {themeName: 'Wood',primaryColor:'#6F1A07',secondaryColor:'#AF9164'},
    {themeName: 'Wine',primaryColor:'#731963',secondaryColor:'#C6878F'},
    {themeName: 'Glitter',primaryColor:'#642CA9',secondaryColor:'#FF36AB'}
  ]
  colorPelletes.forEach((colorPellete)=>{
    const selectedClassName = `themename_${colorPellete.themeName.toLowerCase()}primarycolor${colorPellete.primaryColor.replaceAll("#","").toLowerCase()}secondarycolor${colorPellete.secondaryColor.replaceAll("#","").toLowerCase()}`;
    $(`#brand_setting_color_palet_input .choices-group .choice.color_palet_${selectedClassName} label`)
      .after(`<div>
    <span style="display:inline-block;width:28px;height:28px;border-radius:5px;background:${colorPellete.primaryColor};"></span>
       <span style="display:inline-block;width:28px;height:28px;border-radius:5px;background:${colorPellete.secondaryColor};"></span>
    </div>`)
  })
  $('#brand_setting_color_palet_input fieldset.choices').append(`<div style="margin:0 auto;">
    <p style="margin:0;color:#b5b5b5;font-weight:300;font-size:13px">Example preview</p>
    <div style="widht:240px;">
      <img id="color-pallate-preview-image" src="/assets/Product-color-template.png" />
    </div>
  </div>`)

  setTimeout(()=>{
    const themeName = $("#brand_setting_color_palet_input .choices-group input:checked");
    if(themeName){
      const id = themeName.attr("id")?.substring(36,themeName.attr("id").indexOf("primary"));
      $("#color-pallate-preview-image").attr("src",`/assets/${id}.png`)
    }
  },300)
  $(".special-radio-color-pallate").on("change",function() {
    const themeName = $(this).attr("id").substring(36,$(this).attr("id").indexOf("primary"));
    $("#color-pallate-preview-image").attr("src",`/assets/${themeName}.png`)
  })
})

$(document).on("click", ".catalogue-active-span", function (event) {
  var id = this.getAttribute('data-id');
  var switchElem = document.getElementById('catalogue-active-switch-' + id)
  $.ajax({
    type: "PUT",
    url: '/catalogues/toggle_status',
    data : { 'id': id, 'active': !switchElem.checked },
    success: function(response){
      var elemId = 'catalogue-active-switch-' + response.id
      document.getElementById(elemId).checked = response.active
      // if(response.success){
      //   alert('Status successfully updated!')
      // } else {
      //   alert('Error while updating status! (Required data missing for the product)');
      // }
    }
  });
});

function copyText() {
  /* Get the div field */
  var copyTextDiv = document.getElementById("3rdpartyapikey11");
  document.getElementById("custom-tooltip").style.display = "inline";
  navigator.clipboard.writeText(copyTextDiv.innerHTML);
  setTimeout( function() {
    document.getElementById("custom-tooltip").style.display = "none";
  }, 1000)
}


$(document).ready(function () {
  if($("#index_table_partner_configurations").length !== 0){
    const rows = $("#index_table_partner_configurations tbody tr td.col-partner")
    let rowElementName = null;
    rows.each(function(index) {
      if($(this).text().includes('Razorpay')){
        rowElementName = $(this).parent().attr("id")
      }
    });
    //$(`#${rowElementName} td.col-password div`).addClass("pass")
    // $(`#${rowElementName} td.col-password div`).append(`&nbsp;&nbsp;<span onclick="window.open('https://intercom.help/engineerai/en/articles/6258382-razorpay-help-guide','_blank')" style="cursor:pointer;color:#4bacfe;font-size:14px;font-style:italic">(info)</span>`)
    if(rowElementName && $("#3rdpartyapikey").data("api")){

      $(`#${rowElementName} td.col-actions div.table_actions a.member_link`).css("display","none")
      $(`#${rowElementName} td.col-actions div.table_actions`).append(`<a style="margin-left:38px;" class="view_link member_link" target="_blank" title="View Dashboard" href="https://dashboard.razorpay.com/signin?screen=sign_in">View Dashboard</a>`)
    }


    const rowsforpassword = $("#index_table_partner_configurations tbody tr td.col-partner")
    let rowpasswordElementName = null;
    rowsforpassword.each(function(index) {
      if('Shiprocket' === $(this).text()){
        rowpasswordElementName = $(this).parent().attr("id")
        if($(`#${rowpasswordElementName} td.col-password div`).text().trim().toLowerCase() === "na"){
          $(`#${rowpasswordElementName} td.col-password div`).removeClass("pass")
        }
      }
      if('Razorpay' === $(this).text()){
        rowpasswordElementName = $(this).parent().attr("id")
        if(!$(`#${rowpasswordElementName} td.col-password div`).data("api")){
          $(`#${rowpasswordElementName} td.col-password div`).removeClass("pass")
          $(`#${rowpasswordElementName} td.col-password i`).css("display","none")
        }
      }
    });

  }

})
