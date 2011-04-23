# gems:
require 'rubygems'
require 'sinatra/base'
require 'redis'
require 'slim'
require 'less'
require 'digest/sha1'
require 'pony'

# local includes
require 'config'
require 'helpers'
require 'models'

class SetlistApp < Sinatra::Base
	set :redis, 'redis://localhost:6379/0'
	set :sess_length, 60*60*3 # 3 hrs
	set :r, Redis.new
	redis = r

	helpers do
		def user_or_login()
			unless @user
				redirect to('/login')
			end
		end
	end	

	before do
		@scripts = []

		# is the user logged in?
		if session.has_key? :auth
			id = redis.get('auth/' + session[:auth])
			redis.expire('auth/' + session[:auth], settings.sess_length)
			if id
				# yes? set the @user variable
				@user = {}
				@user[:id] = id
				@user[:email] = redis.get 'user/' << id.to_s << '/email'	
				@user[:bands] = redis.smembers 'user/' << id.to_s << '/bands'
			else
				session.delete :auth
			end
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
		['email', 'password'].each do |p|
			if params[p].empty?
				halt 400, "No #{p} specified."
			end
		end

		unless is_email(params['email'])
				halt 400, "Bad email address"
		end

		id = redis.get('user/email/' + params[:email])

		if id
			# user exists. check password
			stored = redis.get("user/#{id}/password")
			input = myhash(params[:password]) 

			if stored and stored == input 
				# password is good
				login_user(id)
			else
				# password is bad
				halt 400, "Bad password"
			end
		else
			# no user. create a signup token and email them
			hashed = myhash(params[:password])
			signup = Digest::SHA1.hexdigest(Time.now.to_i.to_s)
			email = params[:email]		

			redis.hmset('signup/' + signup, 'email', email,
																	 'password', hashed)
			redis.expire('signup/' + signup, 60*60*24*30)

			link = url('/signup/' + signup)
			# send an email with link to signup token (e6b32)
			Pony.mail(:to => email,
					:from => 'eric@vawks.com', 
					:subject => 'Setlist Account Activation',
					:body => "Please go to #{link} \n\nThis link is good for 30 days.")

			# TODO: flash a "we emailed you" message
			# redirect to '/'
			"An activation link has ben emailed to you. This link is good for 30 days."
		end
	end

	get '/signup/:token' do
		user = redis.hgetall('signup/' + params[:token])

		if !user.empty?
			#return user['email'].inspect
			# create a user with the given email and password
			id = redis.incr 'global/nextUserID'
			id = id.to_s
			u = 'user/' + id
			redis.set(u + '/email', user['email'])
			redis.set(u + '/password', user['password'])
			redis.set('user/email/' + user['email'], id) 
			redis.del('signup/' + params[:token])
			login_user(id)
		else
			halt 404		
		end
	end

	get '/logout' do
		if session.has_key? :auth
			redis.del('auth/' + session[:auth])
			session.delete :auth
		end

		redirect to '/login'
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

		if params[:band_name].empty?
			halt 400, 'No band name specified.'
		end

		# make a band
		id = redis.incr 'global/nextBandID'
		id = id.to_s
		band = 'band/' + id
		redis.set(band + '/name', params[:band_name])
		redis.sadd(band + '/users', @user[:id])
		redis.sadd(band + '/admins', @user[:id])
		redis.sadd('user/' + @user[:id].to_s + '/bands', id)

		redirect('/band/' + id)
	end

	get '/band/:band' do
		user_or_login

		@band = Band.new(params[:band])
		@lists = @band.lists.map do |id|
			List.new(id)
		end

		@song_count = @band.song_count
		@total_time = nice_time(@band.length)
		slim :band
	end

	get '/band/:band/songs' do
		user_or_login

		@band = Band.new(params[:band])
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

		id = redis.incr('global/nextSongID').to_s
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

	get '/band/:band/new_list' do
		user_or_login

		@band = Band.new(params[:band])
		@songs = @band.songs.map do |song|
			Song.new(song)
		end
		
		@list = List.new

		@scripts << '/scripts/list.js'
		slim :list
	end

	post '/band/:band/new_list' do
		user_or_login

		band = params['band']
		songs = params['songs']

		['list_name', 'songs'].each do |p|
			if params[p].empty?
				halt 400, "No #{p} specified."
			end
		end

		# TODO: make sure there's at least one songs

		list = redis.incr('global/nextListID')
		
		songs.each do |song|
			redis.lpush("list/#{list}/songs", song)
		end

		redis.set("list/#{list}/name", params[:list_name])
		redis.sadd("band/#{band}/lists", list)

		list.to_s
	end

	get '/band/:band/list/:list' do
		user_or_login

		@band = Band.new(params[:band])
		@band_songs = @band.songs.map do |song|
			Song.new(song)
		end
		
		@list = List.new(params[:list])
		@list_songs = @list.songs.map do |song|
			Song.new(song)
		end

		slim :list
	end

	get '/band/:band/list/:list/delete' do
		user_or_login

		# confirm that user "owns" the list

		band = params[:band]
		list = params[:list]	

		redis.srem("band/#{band}/lists", list)
		redis.del("list/#{list}/name", "list/#{list}/songs")

		redirect to "/band/#{band}"
	end

end

