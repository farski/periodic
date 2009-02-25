module Periodic
	extend self
	
	def parse(string, options = {})
		return nil if !string.match(/\d/)
		options[:bias] ||= :seconds
		seconds = expand(delimit(string, options))
		return (options[:seconds] == :partial && !seconds.is_a?(Float)) ? seconds.to_f : seconds
	end
	
	def output(seconds, format = '%y:%n:%w:%d:%h:%m:%s', precision = :round)
		return nil unless (seconds.is_a?(Integer) || seconds.is_a?(Float)) && format.match(/%/)
		precision = (precision == :exact ? 'to_f' : 'to_i')
		
		names = %w{ seconds minutes hours days weeks months years }
		factors = [1, 60, 60, 24, 7, 30, 365]
		matchers = [/%s/, /%m/, /%h/, /%d/, /%w/, /%n/, /%y/]
		
		units = matchers.inject(Array.new) { |cache, m| cache << (format.match(m) ? names[matchers.index(m)] : nil) }.compact
		units.reverse.each_with_index do |u, i|
			factor = eval(factors[0,names.index(u)+1].join("*"))
			value = (seconds.send(units[i+1] ? 'to_i' : precision) / factor)
			seconds -= (value*factor)
			value = ((format.match(/:/) && value.to_s.length == 1) ? ("0" + value.to_s) : value.to_s) 
			format.gsub!(matchers[names.index(u)], value)
		end
		return sanitize(format).strip
	end
	
private

	def delimit(string, options)
		units = [:seconds, :minutes, :hours, :days, :weeks, :months, :years, :decades, :centuries, :millennia]
		abbrs = %w{s m h d w n y a c b}
		if string.match(/[a-zA-Z]/)
			string.concat("sec") if string[-1,1].match(/\d/)			
			parts = normalize_text(string).split(' ').sort{|x,y| abbrs.index(y[-1,1]) <=> abbrs.index(x[-1,1]) }				
			string = ""
			parts.each_with_index do |s, i|
				string << (s.to_i == s.to_f ? s.to_i : s.to_f).to_s + ":"
				if parts[i+1]
					((abbrs.index(s[-1,1]) - abbrs.index(parts[i+1][-1,1]))-1).times{ string << '0:' }
				elsif s[-1,1] != "s"
					(abbrs.index(s[-1,1])).times{ string << '0:' }
				end
			end
			string.chop!
		end
		minimum_bias = string.match(/:/) ? string.scan(/:/).size : 0			
		options[:bias] = units[minimum_bias] if units.index(options[:bias]) < minimum_bias
		units.reverse.index(options[:bias]).times{ string.insert(0, '00:') }			
		(units.index(options[:bias])-minimum_bias).times{ string.concat(':00') }
		return string
	end
	
	def normalize_text(string)
		[/(and |,)/, /( )/].each{ |m| string.gsub!(m, '') }
		string.gsub!(/(\d)([a-zA-Z]+)/, '\1\2 ')
		{:s=>/(s\w*)/,:n=>/(mo\w*)/,:b=>/(m\w*l\w*)/,:m=>/(m\w*)/,:h=>/(h\w*)/,:a=>/(d\w*c\w*)/,:d=>/(d\w*)/,:w=>/(w\w*)/,:y=>/(y\w*)/,:c=>/(c\w*)/}.each{ |k,v| string.gsub!(v, k.to_s) }
		string
	end
		
	def expand(string)
		factors, seconds = [1, 60, 3600, (3600*24), (3600*24*7), (3600*24*30), (3600*24*365.25), (3600*24*365.25*10), (3600*24*365.25*100), (3600*24*365.25*1000)], 0
		string.split(/:/).each_with_index { |n, i| seconds += n.to_f * factors.reverse[i] }
		return (seconds == seconds.to_i ? seconds.to_i : seconds)
	end

	def sanitize(string)
		if string.match(/:/)
			string.gsub!(/^([0:]*)/, '').gsub!(/:(\d[^\d])/, ':0\1')
		else
			string.gsub!(/^(0[a-zA-Z, ]+)*/, '').gsub!(/([a-zA-Z, ]+)(0[^!]([a-zA-Z ]+)*)*([1-9]+)*/, '\1\4')
		end
		string.gsub!(/!*/, '')
	end
end