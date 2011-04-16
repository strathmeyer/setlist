require 'rubygems'
require 'sinatra/base'
require 'redis'
require 'slim'
require 'less'
require 'digest/sha1'
require 'models'

class MyApp < Sinatra::Base
	use Rack::Static, :urls => ["/css", "/images"], :root => "public"

	set :redis, 'redis://localhost:6379/0'
	redis = Redis.new
	
	enable :sessions
	set :session_secret, '34nnt0b09isn3j23nrkj3rn23jndj90b90j0dfi4moimoinbgnbklmo'
	
	enable :method_override # fake PUT and DELETE via name="_method"
	set :slim, :pretty => true
	
	helpers do
		def plural(singular, count, plural=nil)
			plural ||= singular + 's'		

			if count.to_i == 1
				singular
			else
				plural
			end
		end
	end

	before do
		redis.mset 'user/1/email', 'eric@vawks.com',
			'user/1/password', myhash('rules'),
			'user/email/eric@vawks.com', 1
		
		# is the user logged in?
		if true
			id = 1

			# yes? set the @user variable
			@user = {}
			@user[:id] = id
			@user[:email] = redis.get 'user/' << id.to_s << '/email'	
			@user[:bands] = redis.smembers 'user/' << id.to_s << '/bands'
		else
			# no? redirect to login
			throw "barf"
		end
	end


	get '/' do
		# add login in here:
		# if logged redirect to /dashboard
		# else redirect to /login
		redirect to('/dashboard')
	end

	get '/dashboard' do
		@bands = []
		
		@user[:bands].each do |id|
			@bands << Band.new(id)
		end

		slim :dashboard
	end

	post '/new_band' do
		# make a band
		id = redis.incr 'globalNextBandID'
		id = id.to_s
		band = 'band/' + id
		redis.set(band + '/name', params[:band_name])
		redis.sadd(band + '/users', @user[:id])
		redis.sadd(band + '/admins', @user[:id])
		redis.sadd('user/' + @user[:id].to_s + '/bands', id)

		redirect('/dashboard')
	end

	get '/band/:id' do
		@band = Band.new(params[:id])
	
		@lists = @band.lists.map do |id|
			List.new(id)
		end

		@song_count = @band.song_count
		@total_time = nice_time(@band.length)
		slim :band
	end

	get '/band/:id/songs' do
		@band = Band.new(params[:id])
		@songs = @band.songs.map do |song|
			Song.new(song)
		end

		@songs.sort_by do |s|
			s.name
		end

		slim :songs
	end

	post '/band/:band/songs' do
		id = redis.incr 'globalNextSongID'
		id = id.to_s
		key = 'song/' + id
		redis.set(key + '/name', params[:name])

		length = extract_integer(params[:length])

		redis.set(key + '/length', length)
		redis.sadd('band/' + params[:band] + '/songs', id)

		redirect '/band/' + params[:band] + '/songs'
	end
end

def nice_time(minutes)
	minutes = minutes.to_i

	if minutes == 0 then
		"0m"
	else
		hour = minutes / 60
		min = minutes % 60

		out = []

		out << "#{hour}h" if hour > 0
		out << "#{min}m" if min > 0

		out.join(' ')	
	end
end

def myhash(input)
	Digest::SHA1.hexdigest('zx0-cv8zxco90.,32m4n2.,3m4noadf' << \
			Digest::SHA1.hexdigest(input.to_s << 'woweifnweofinweofi'))
end

def extract_time(text)
	hours = 0
	mins = 0

	hmatches = /(\d+)h/.match(text)
	hours = hmatches[1].to_i if hmatches

	mmatches = /(\d+)m/.match(text)
	mins = mmatches[1].to_i if mmatches

	return (hours * 60) + mins
end

def extract_integer(text)
	matches = /(\d+)/.match(text)
	
	if matches
		matches[1]
	else
		0
	end
end
