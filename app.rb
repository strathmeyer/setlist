require 'rubygems'
require 'sinatra/base'
require 'redis'
require 'slim'
require 'less'


class MyApp < Sinatra::Base
	redis = Redis.new

	set :redis, 'redis://localhost:6379/0'
	disable :logging

	redis.set "song", 320

	get '/:x?' do
		@name = nice_time(redis.get 'song')
		puts params[:x].inspect
		if params[:x] == 'x'
			@name = 'grrrr'
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
