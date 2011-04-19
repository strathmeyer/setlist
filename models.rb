require 'redis'

class Band
	attr_reader :id, :name, :song_count, :songs, :lists, :length

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

	def to_s
		@name
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

	def to_s
		@email
	end
end

class List
	attr_reader :id, :name, :length, :sets 

#	list/<list_id>/name = list name
#	list/<list_id>/length = number of minutes total
#	list/<list_id>/sets = number of sets in the list
#	list/<list_id>/<set_index> = a list of <song_id>s. note that set_index is 1 indexed

	def initialize(id=nil)
		@sets = []

		if id
			redis = Redis.new
			@id = id
			prefix = 'list/' + id.to_s
			@name = redis.get prefix + '/name'
			@length = redis.get prefix + '/length'
			set_count = redis.scard(prefix + '/sets') or 0
			
			set_count.times do |i|
				n = (i + 1).to_s

				@sets << redis.lrange(prefix + '/' + n, 0, -1)
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
