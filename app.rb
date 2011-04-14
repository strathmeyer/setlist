require 'rubygems'
require 'sinatra/base'
#require 'redis'
require 'redis-store'
require 'slim'
require 'less'


class MyApp < Sinatra::Base
	set :redis, 'redis://localhost:6379/0'
	use Rack::Session::Redis, :redis_server => settings.redis
	enable :method_override


	redis = Redis.new
	redis.set "song", 320

	get '/:x?' do
		@name = nice_time(redis.get 'song')
		puts params[:x].inspect
		
		session[:visited_at] = DateTime.now.to_s

		if params[:x] == 'x'
			@name = 'balls'
			@name = session[:visited_at]
			slim :foo, :layout => :xlayout	
		else
			slim :foo
		end
	end
end

def nice_time(minutes)
	minutes = minutes.to_i
	hour = minutes / 60
	min = minutes % 60

	out = []

	out << "#{hour}h" if hour > 0
	out << "#{min}m" if min > 0

	out.join(' ')	
end
