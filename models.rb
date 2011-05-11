require 'redis'

class Band
	attr_accessor :id, :name, :song_count, :songs, :lists, :length

	def initialize(id)
		redis = Redis.new
		@id = id
		prefix = 'band/' + id.to_s
		@name = redis.get prefix + '/name'
		@song_count = redis.scard prefix + '/songs'
		@songs = redis.smembers prefix + '/songs'
		@lists = redis.smembers prefix + '/lists'	
		@length = redis.get prefix + '/length'
	end

	def users
		redis = Redis.new

		unless @users
			ids = redis.smembers 'band/' + @id + '/users'

			@users = ids.map do |u|
				User.new u
			end
		end

		@users
	end

	def to_s
		@name
	end
end

class User
	attr_reader :id, :email, :bands

	def initialize(id)
		redis = Redis.new
		@id = id
		@email = redis.get 'user/' + id + '/email'
		@bands = redis.smembers 'user/' + id + '/bands'
	end

	def to_s
		@email
	end
end

class List
	attr_accessor :id, :name, :length, :songs 
#	list/<list_id>/name = list name
#	list/<list_id>/length = number of minutes total
#	list/<list_id>/sets = number of sets in the list
#	list/<list_id>/<set_index> = a list of <song_id>s. note that set_index is 1 indexed

	def initialize(id=nil)
		@songs = []
		@length = 0

		if id
			redis = Redis.new
			@id = id
			prefix = 'list/' + id.to_s
			@name = redis.get prefix + '/name'
			@length = redis.get prefix + '/length'
			@songs = redis.lrange(prefix + '/songs', 0, -1).map do |song|
				match = /(\d+):(.+)/.match(song)
				
				if match
					song = Object.new
					def song.length
						@length
					end
					def song.name
						@name
					end
					def song.init(length, name)
						@name = name
						@length = length
					end

					song.init(match[1], match[2])
					song
				end
			end
		end
	end
	
end

class Song
	attr_reader :id, :name, :length
	
	def initialize(id)
		redis = Redis.new

		@id = id
		prefix = 'song/' + id.to_s
		@name = redis.get prefix + '/name'
		@length = redis.get prefix + '/length'
	end
end
