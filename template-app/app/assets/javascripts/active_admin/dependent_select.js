$(document).ready(function() {
	$(document).on('has_many_add:after', function(e, insertedItem, originalEvent) {
		$('.has_many_fields').each(function (i, field){
	    $(field).find('select[data-option-dependent=true]').each(function (j) {
				var observer_dom_id = $(this).attr('id');
				var observed_dom_id = $(this).data('option-observed');
				var url_mask        = $(this).data('option-url');
				$(this).data('option-url', url_mask);
				$(this).data('option-observed', observed_dom_id);
				var key_method      = "id"; //$(this).data('option-key-method');
				var value_method    = "name"; //$(this).data('option-value-method');
				var prompt          = $(this).has('option[value=""]').length ? $(this).find('option[value=""]') : $('<option>').text('?');
				var regexp          = /:[0-9a-zA-Z_]+/g;

				var observer = $('select#'+ observer_dom_id);
				var observed = $('select#'+ observed_dom_id);

				if (!observer.val() && observed.length > 1) {
					observer.attr('disabled', true);
				}
				observed.unbind( "change" );

				observed.on('change', function() {
					url = url_mask.replace(regexp, function(submask) {
						dom_id = submask.substring(1, submask.length);
						return $("select#"+ dom_id).val();
					});

					observer.empty();
					setTimeout(ll(url, observer, key_method, value_method),500);
				});
			});
		})
  });
	$('select[data-option-dependent=true]').each(function (i) {

		var observer_dom_id = $(this).attr('id');
		var observed_dom_id = $(this).data('option-observed');
		var url_mask        = $(this).data('option-url');
		var key_method      = "id"; //$(this).data('option-key-method');
		var value_method    = "name"; //$(this).data('option-value-method');

		var prompt          = $(this).has('option[value=""]').length ? $(this).find('option[value=""]') : $('<option>').text('?');
		var regexp          = /:[0-9a-zA-Z_]+/g;

		var observer = $('select#'+ observer_dom_id);
		var observed = $('select#'+ observed_dom_id);

		if (!observer.val() && observed.length > 1) {
			observer.attr('disabled', true);
		}
		observed.on('change', function() {
			url = url_mask.replace(regexp, function(submask) {
				dom_id = submask.substring(1, submask.length);
				return $("select#"+ dom_id).val();
			});

			observer.empty();

			setTimeout(ll(url, observer, key_method, value_method),500);

		});
	});
});

function custom_template(obj){
        var data = $(obj.element).data();
        var text = $(obj.element).text();
        if(data && data['img_src']){
            img_src = data['img_src'];
            template = $("<div><img src=\"" + img_src + "\" style=\"width:100%;height:150px;\"/><p style=\"font-weight: 700;font-size:14pt;text-align:center;\">" + text + "</p></div>");
            return template;
        }
    }

function ll(url, observer, key_method, value_method) {
	$.getJSON(url, function(data) {
		observer.append($('<option>'))
		$.each(data, function(i, object) {
			if(object['data-img_src']) {
				observer.append($('<option>').attr('value', object[key_method]).text(object[value_method]).attr('data-img_src', object['data-img_src']));
			} else {
				observer.append($('<option>').attr('value', object[key_method]).text(object[value_method]));

			}
			observer.attr('disabled', false);
		});

	})
	  var options = {
	      'templateSelection': custom_template,
	      'templateResult': custom_template
	  }
  $('#bucket_picture_associator_images').select2(options);

}
