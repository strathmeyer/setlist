require 'redis'

class Band
	attr_reader :id, :name, :song_count, :songs

	def initialize(id)
		redis = Redis.new
		@id = id
		prefix = 'band/' + id.to_s
		@name = redis.get prefix + '/name'
		@song_count = redis.scard prefix + '/songs'
		@songs = redis.smembers prefix + '/songs'
	end
end

class User
	attr_reader :id, :email, :song_count, :songs

	def initialize(id)
		redis = Redis.new
		@id = id
		@name = redis.get('band/' << id.to_s << '/name')
		@song_count = nil
	end



end
