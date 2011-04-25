jQuery(function ($) {
	var songs = $('#song-container'),
			songTemplate;

	songTemplate = $('<div />', {'class': 'song'})

	$('#song-container').sortable();

	// add songs to the list
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

		$('.list-length').text(
			parseInt($('.list-length').text(), 10) + parseInt(song.length, 10)
		);
	});

	// highlight on Add Button hover
	$('#list-songs .add-song').hover(function () {
		$(this).closest('tr').addClass('hover');
	}, function () {
		$(this).closest('tr').removeClass('hover');
	});

	// remove songs from the list
	$('#song-container').delegate('.remove-song', 'click', function (e) {
		var $this = $(this),
				song = $this.closest('.song'),
				length = parseInt(song.attr('length'), 10);

		e.preventDefault();

		$('.list-length').text(
			parseInt($('.list-length').text(), 10) - length
		);

		song.remove();		
	});

	// save the list
	$('#submit-btn').click(function (e) {
		var songs = [],
				listName = $('#list-name').val(),
				length = $('#list-detail .list-length').text(), 
				bandID = $('#band-hd').attr('band-id');

		e.preventDefault();

		if (!listName) {
			alert('Please enter a list name.');
			return;
		}

		$('#song-container .song').each(function () {
				var $this = $(this),
						length = $this.attr('length'),
						name = $this.find('.name').text();

				songs.push(length + ':' + name);
		});

		$.post(window.location, {
				list_name: listName, 
				songs: songs,
				length: length
			}, function (listID) {

			window.location = '/band/' + bandID; // + '/list/' + listID;
		});
	});

});
