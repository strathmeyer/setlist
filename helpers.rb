class SetlistApp < Sinatra::Base
	helpers do

		def plural(singular, count, plural=nil)
			plural ||= singular + 's'		

			if count.to_i == 1
				singular
			else
				plural
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
				matches[1].to_i
			else
				0
			end
		end

	end
end