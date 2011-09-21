jQuery(function ($) {
	$("[placeholder]").textPlaceholder();
});

function followHref(e) {
  e.preventDefault();
	window.location = jQuery(this).attr('href');
};
