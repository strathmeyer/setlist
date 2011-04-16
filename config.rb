class SetlistApp < Sinatra::Base
	use Rack::Static, :urls => ["/css", "/images", "/scripts"], :root => "public"
	
	enable :sessions
	set :session_secret, '34nnt0b09isn3j23nrkj3rn23jndj90b90j0dfi4moimoinbgnbklmo'
	
	enable :method_override # fake PUT and DELETE via name="_method"
	set :slim, :pretty => true
end
