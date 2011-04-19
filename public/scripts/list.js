jQuery(function ($) {
	var songs = $('#song-container'),
			songTemplate;

	songTemplate = $('<div />', {'class': 'song'})

	$('#list-songs').delegate('.add-song', 'click', function (e) {
		var $this = $(this),
				tr = $this.closest('tr'),
				songTemplate = _.template($('#song-template').html()),
				song; 

		e.preventDefault();

		song = {
			id: tr.attr('song-id'),
			name: tr.find('.name').text(),
			nice_length: tr.find('.length').text(),
			length: tr.attr('length')
		};

		songs.append(songTemplate(song));

		$('.set-length').text(
			parseInt($('.set-length').text(), 10) + parseInt(song.length, 10)
		);
	});

	$('#list-songs .add-song').hover(function () {
		$(this).closest('tr').addClass('hover');
	}, function () {
		$(this).closest('tr').removeClass('hover');
	});


	$('#song-container').delegate('.remove-song', 'click', function (e) {
		var $this = $(this),
				song = $this.closest('.song'),
				length = parseInt(song.attr('length'), 10);

		e.preventDefault();

		$('.set-length').text(
			parseInt($('.set-length').text(), 10) - length
		);

		song.remove();		
	});

});
