setlist
========

Add songs, organize into sets, print setlists.


DB Schema
---------

###Global###
- global/nextUserID
- global/nextBandID
- global/nextListID

###Auth###
- auth/&lt;auth_key&gt; = &lt;user_id&gt;

###Signup###
- signup/&lt;signup_token&gt; = {email: &lt;email&gt;, password: &lt;hashed&gt;}

###User###
- user/&lt;user_id&gt;/email = email address
- user/&lt;user_id&gt;/password = hashed password
- user/&lt;user_id&gt;/bands = set of &lt;band_id&gt;s
- user/email/&lt;email_address&gt; = &lt;user_id&gt;
- <del>user/&lt;user_id&gt;/auth = if user is logged it. their current &lt;auth_key&gt;</del> (not used. we currently allow a user to log in multiple places)

###Band###
- band/&lt;band_id&gt;/name = band name
- band/&lt;band_id&gt;/users = set of &lt;user_id&gt;s
- band/&lt;band_id&gt;/admins = set of &lt;user_id&gt;s which are admins for the band
- band/&lt;band_id&gt;/songs = set of &lt;song_id&gt;s
- band/&lt;band_id&gt;/lists = set of &lt;list_id&gt;s

###List###
- list/&lt;list_id&gt;/name = list name
- list/&lt;list_id&gt;/length = number of minutes total
- list/&lt;list_id&gt;/songs = a list of "123:songname" strings
