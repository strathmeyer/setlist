$(function() {
	$('.delete-song').one('click', function(e) {
		e.preventDefault();

		var tr = $(this).closest('tr'),
				song = tr.attr('song-id'),
				band = tr.attr('band-id');

		$.post('/band/' + band + '/song/' + song, {_method: 'DELETE'}, function(data) {
			tr.fadeOut('fast');
		});

	});
});
