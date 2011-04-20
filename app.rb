# gems:
require 'rubygems'
require 'sinatra/base'
require 'redis'
require 'slim'
require 'less'
require 'digest/sha1'

# local includes
require 'config'
require 'helpers'
require 'models'

class SetlistApp < Sinatra::Base
	set :redis, 'redis://localhost:6379/0'
	redis = Redis.new

	helpers do
		def user_or_login()
			unless @user
				redirect to('/login')
			end
		end
	end	

	before do
		@scripts = []

		redis.mset 'user/1/email', 'eric@vawks.com',
			'user/1/password', myhash('rules'),
			'user/email/eric@vawks.com', 1
		
		# is the user logged in?
		# if we have a session hash, and it matches a user id in redis
		# keep that hash->user entry allive in redis.
		# log the user in
		if true
			id = 1

			# yes? set the @user variable
			@user = {}
			@user[:id] = id
			@user[:email] = redis.get 'user/' << id.to_s << '/email'	
			@user[:bands] = redis.smembers 'user/' << id.to_s << '/bands'
		end
	end

	get '/' do
		user_or_login

		redirect to('/dashboard')
	end

	get '/login' do
		redirect to('/dashboard') if @user

		slim :login
	end

	post '/login' do
		# if there's a user with that email
			# if the user/pass matches
				# set some session hash
				# record that hash in redis expire in 30 min
				# redirect to dashboard
			# else
				# flash "bad password". redirect to /
		# else
			# hash password
			# random hash for signup token
			# redis.hash('signup/e6b32', {email: 'foo', pass_hash: 'ab42e...'})
			# send an email with link to signup token (e6b32)
			# flash a "we emailed you" message. redirect to /
	end

	get '/signup/:token' do
		# if the tag 'signup/:token' exists
			# create a user with the given email and password
			# flash a "welcome!" message. redirect to dashboard
		# else
		halt 404		
		
	end

	get '/dashboard' do
		user_or_login

		@bands = []
		
		@user[:bands].each do |id|
			@bands << Band.new(id)
		end

		slim :dashboard
	end

	post '/new_band' do
		user_or_login

		unless params.has_key? :band_name
			halt 400, 'No band name specified.'
		end

		# make a band
		id = redis.incr 'globalNextBandID'
		id = id.to_s
		band = 'band/' + id
		redis.set(band + '/name', params[:band_name])
		redis.sadd(band + '/users', @user[:id])
		redis.sadd(band + '/admins', @user[:id])
		redis.sadd('user/' + @user[:id].to_s + '/bands', id)

		redirect('/band/' + id)
	end

	get '/band/:id' do
		user_or_login

		@band = Band.new(params[:id])
		@lists = @band.lists.map do |id|
			List.new(id)
		end

		@song_count = @band.song_count
		@total_time = nice_time(@band.length)
		slim :band
	end

	get '/band/:id/songs' do
		user_or_login

		@band = Band.new(params[:id])
		@songs = @band.songs.map do |song|
			Song.new(song)
		end

		@songs = @songs.sort_by do |s|
			s.name
		end
		
		@scripts << '/scripts/songs.js'
		slim :songs
	end

	post '/band/:band/songs' do
		user_or_login

		id = redis.incr('globalNextSongID').to_s
		key = 'song/' + id

		redis.set(key + '/name', params[:name])
		redis.sadd('band/' + params[:band] + '/songs', id)

		length = extract_integer(params[:length])
		length = 3 if length < 3
		redis.set(key + '/length', length)
		redis.incrby('band/' + params[:band] + '/length', length)

		redirect '/band/' + params[:band] + '/songs'
	end

	delete '/band/:band/song/:song' do
		user_or_login

		key = 'song/' + params[:song]

		length = redis.get(key + '/length')
		redis.del(key + '/name', key + '/length')
		redis.srem('band/' + params[:band] + '/songs', params[:song])
		redis.decrby('band/' + params[:band] + '/length', length)
	end

	get '/band/:id/new_list' do
		user_or_login

		@band = Band.new(params[:id])
		@songs = @band.songs.map do |song|
			Song.new(song)
		end
		
		@list = List.new

		@scripts << '/scripts/list.js'
		slim :list
	end

	get '/band/:band/list/:list' do
		user_or_login

		@band = Band.new(params[:band])
		@band_songs = @band.songs.map do |song|
			Song.new(song)
		end
		
		@list = List.new(params[:list])
		@list_songs = @band.songs.map do |song|
			Song.new(song)
		end


		slim :list
	end


end

