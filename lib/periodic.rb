require 'bigdecimal'

module Periodic
	extend self
	
	def parse(string, options = {})
		return nil if !string.match(/\d/)
		options[:bias] ||= :seconds
		seconds = expand(delimit(string, options))
		return (options[:seconds] == :partial && !seconds.is_a?(Float)) ? seconds.to_f : seconds
	end
	
	def output(seconds, format_or_options = '%y:%n:%w:%d:%h:%m:%s', options = { :precision => nil })
		case format_or_options
			when String then format = format_or_options
			when Hash then format, options = (options[:format] ? options[:format] : '%y:%n:%w:%d:%h:%m:%s'), format_or_options
		end
		seconds = parse(seconds) if seconds.is_a?(String)
		return nil unless ((seconds.is_a?(Integer) || seconds.is_a?(Float)) && format.match(/%/))		
		
		names = %w{ seconds minutes hours days weeks months years }
		factors = [1, 60, 60, 24, 7, 30, 365]
		directives = [/%s/, /%m/, /%h/, /%d/, /%w/, /%n/, /%y/]
		unused_seconds = seconds

		units = directives.inject(Array.new) { |cache, m| cache << (format.match(m) ? names[directives.index(m)] : nil) }.compact
		units.reverse.each_with_index do |u, i|
			unit_factor = eval(factors[0,names.index(u)+1].join("*"))
			unit_quotient = unused_seconds.to_f / unit_factor
			
			unit_value = (units[i+1] ? unit_quotient.to_i : round_with_precision(unit_quotient.to_f, options[:precision]))

			unit_value = unit_value.to_i if options[:precision] == 0 || (seconds.is_a?(Integer) && (round_with_precision(unit_value % 1, 5) == 0) && !options[:precision])

			unused_seconds = BigDecimal(unused_seconds.to_s) - BigDecimal((unit_value*unit_factor).to_s)
			unit_value = unit_value.to_f if (unused_seconds == 0 && !options[:precision] && seconds.is_a?(Float))

			unit_value = ((format.match(/:/) && unit_value.to_s.length == 1) ? ("0" + unit_value.to_s) : unit_value.to_s)
			format.gsub!(directives[names.index(u)], unit_value.to_s)
		end

		return sanitize(format).strip	
	end
	
private

	def delimit(string, options)
		units = [:seconds, :minutes, :hours, :days, :weeks, :months, :years, :decades, :centuries, :millennia]
		abbrs = %w{s m h d w n y a c b}
		if !string.match(/:/)
			string.concat(options[:bias].to_s) if string[-1,1].match(/\d/)
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
			options[:bias] = units[string.scan(/:/).size] if string.scan(/:/).size < units.index(options[:bias])
		end
		options[:bias] = units[string.scan(/:/).size] if string.scan(/:/).size > units.index(options[:bias])
		(units.reverse.index(options[:bias])).times{ string.insert(0, '00:') }
		(units.index(options[:bias])-string.scan(/:/).size).times{ string.concat(':00') }
		return string
	end
	
	def normalize_text(string)
		[/(and |,)/, /( )/].each{ |m| string.gsub!(m, '') }
		string.gsub!(/(\d)([a-zA-Z]+)/, '\1\2 ')
		{:s=>/(s\w*)/,:n=>/(mo\w*)/,:b=>/(m\w*l\w*)/,:m=>/(m\w*)/,:h=>/(h\w*)/,:a=>/(d\w*c\w*)/,:d=>/(d\w*)/,:w=>/(w\w*)/,:y=>/(y\w*)/,:c=>/(c\w*)/}.each{ |k,v| string.gsub!(v, k.to_s) }
		string
	end
		
	def round_with_precision(number, precision = nil)
		precision.nil? ? number : (number * (10 ** precision)).round / (10 ** precision).to_f
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
			string.gsub!(/^(0[a-zA-Z, ]+)*/, '')
			# string.gsub!(/([a-zA-Z, ]+)(0[^!]([a-zA-Z ]+)*)*([1-9]+)*/, '\1\4')
			string.gsub!(/[ ]+0[ ]*[a-zA-Z]/, '')
			string.gsub!(/([ ]+(0.)*0$)/, '')
		end
		string.gsub!(/!*/, '')
	end
end