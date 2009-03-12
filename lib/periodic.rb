require 'bigdecimal'

module Periodic
	extend self
	
	def parse(string, options = {})
		# can't even try to do anything if the input string doesn't have any number characters
		return nil if !string.match(/\d/)
		
		# default value
		options[:bias] ||= :seconds
		
		# normalize and process the string to get the number of seconds
		seconds = expand(delimit(string, options))
		
		# make seconds a float if the options say to and it isn't already a float
		seconds = seconds.to_f if options[:seconds] == :partial && !seconds.is_a?(Float)		

		return seconds
	end
	
	def print(seconds, format_or_options = '%y:%n:%w:%d:%h:%m:%s', options = { :precision => nil })
		# this allows us to handle a couple different ways of inputing the options and format
		case format_or_options
			when String then format = format_or_options
			when Hash then format, options = (options[:format] ? options[:format] : '%y:%n:%w:%d:%h:%m:%s'), format_or_options
		end
		
		# parse out the seconds if they aren't explicitly given
		seconds = parse(seconds) if seconds.is_a?(String)
		
		# need a copy of the seconds to subtract from as we go, and the format to replace directives with values
		unused_seconds = seconds
		output = format
		
		# can't do much if at this point we don't have at least a number and a valid format
		return nil unless ((seconds.is_a?(Integer) || seconds.is_a?(Float)) && format.match(/%/))		
		
		# define the names, values, and format directives of the various time units
		names, factors = %w{ seconds minutes hours days weeks months years }, [1, 60, 60, 24, 7, 4, 52]
		directives = [/%s/, /%m/, /%h/, /%d/, /%w/, /%n/, /%y/]

		# figure out which units are being used in the format
		units = directives.inject(Array.new) { |cache, m| cache << (format.match(m) ? names[directives.index(m)] : nil) }.compact
		
		# 
		units.reverse.each_with_index do |u, i|
			# the factor for this unit is the product of the factors for all smaller units
			unit_factor = eval(factors[0,names.index(u)+1].join("*"))
			
			# this is the number of remaining seconds expressed in the current unit
			unit_quotient = unused_seconds.to_f / unit_factor
			
			# if there are units left to evaluate, we always want the integer part of the quotient,
			# otherwise we want the value to the given precision
			unit_value = (units[i+1] ? unit_quotient.to_i : round_with_precision(unit_quotient.to_f, options[:precision]))

			# under certain circumstances we want to force the value to become an integer
			unit_value = unit_value.round if options[:precision] == 0 || (seconds.is_a?(Integer) && (round_with_precision(unit_value % 1, 5) == 0) && !options[:precision])

			# subtract the current value as seconds from the unused seconds
			unused_seconds = BigDecimal(unused_seconds.to_s) - BigDecimal((unit_value*unit_factor).to_s)
			
			# if we're out of seconds, under certain circumstances, we want to make sure this value is a decimal
			unit_value = unit_value.to_f if (unused_seconds == 0 && !options[:precision] && seconds.is_a?(Float) && !format.match(/:/))
			unit_value = unit_value.to_f if unused_seconds == 0 && options[:precision] && options[:precision] > 0

			# unit_value = ((output.match(/:/) && unit_value.to_s.length == 1) ? ("0" + unit_value.to_s) : unit_value.to_s)
			output.gsub!(directives[names.index(u)], unit_value.to_s)
		end

		return sanitize(output).strip
	end
	
private

	def expand(string)
		# initialize seconds to 0 and set the number of seconds in each unit factor (minute, hour, etc...)
		factors, seconds = [1, 60, 3600, (3600*24), (3600*24*7), (3600*24*30), (3600*24*365.25), (3600*24*365.25*10), (3600*24*365.25*100), (3600*24*365.25*1000)], 0
		
		# multiply each part of the normalized string by it's appropriate factor
		string.split(/:/).each_with_index { |n, i| seconds += n.to_f * factors.reverse[i] }
		
		# only return a float if we actually need to
		return (seconds % 1 == 0 ? seconds.to_i : seconds)
	end

	def delimit(string, options)
		# set a list of the possible units, and the normalized abbreviations, and a blank sting
		units, abbrs = [:seconds, :minutes, :hours, :days, :weeks, :months, :years, :decades, :centuries, :millennia], %w{s m h d w n y a c b}
		
		# if the string is using text labels...
		if !string.match(/:/)
			# if the string doesn't end in a label, stick the bias (default seconds) at the end as a string
			string.concat(options[:bias].to_s) if string[-1,1].match(/\d/)

			# normaliz the string and put the parts in order from biggest time unit to smallest
			parts = normalize_text(string).split(' ').sort{|x,y| abbrs.index(y[-1,1]) <=> abbrs.index(x[-1,1]) }
			
			string = String.new
						
			parts.each_with_index do |s, i|				
				# extract the number part of this part of the normalized string, and conact it to
				# the final output string, as the simplist Numeric possible
				string << (s.to_i == s.to_f ? s.to_i : s.to_f).to_s + ":"
				
				# if there are any more units left after this one...
				if parts[i+1]					
					# for each unit not included in the string between this one and that one
					# add a zero-value place holder
					((abbrs.index(s[-1,1]) - abbrs.index(parts[i+1][-1,1]))-1).times{ string << '0:' }
					
				# if this is the last unit being evaluated
				# and it's not seconds
				elsif s[-1,1] != "s"					
					# add enough place holders to get to seconds
					(abbrs.index(s[-1,1])).times{ string << '0:' }
				end
			end
			
			# remove a left-over trailing colon
			string.chop!
			
			# if, after changing the text labels to colons, the bias doesn't make sense,
			# reset it to something that does
			options[:bias] = units[string.scan(/:/).size] if string.scan(/:/).size < units.index(options[:bias])
		end
		
		# if the bias is too small for the actual number of units given, set it to the
		# closest appropriate bias
		options[:bias] = units[string.scan(/:/).size] if string.scan(/:/).size > units.index(options[:bias])
		
		# add zero-value placeholders to account for the bias
		((units.reverse.index(options[:bias]))||0).times{ string.insert(0, '00:') }
		((units.index(options[:bias])||0)-string.scan(/:/).size).times{ string.concat(':00') }
		
		return string
	end
	
	def normalize_text(string)
		# strip any spaces or separators from the string
		[/(and |,)/, /( )/].each{ |m| string.gsub!(m, '') }
		
		# insert a space after each number-unit pair
		string.gsub!(/(\d)([a-zA-Z]+)/, '\1\2 ')
		
		# replace unit labels with standardized abbriviations
		# the array is just to make sure certain replacements happen first
		[{:n=>/(mo\w*)/,:b=>/(m\w*l\w*)/,:a=>/(d\w*c\w*)/}, {:n=>/(mo\w*)/,:b=>/(m\w*l\w*)/,:m=>/(m\w*)/,:h=>/(h\w*)/,:a=>/(d\w*c\w*)/,:d=>/(d\w*)/,:w=>/(w\w*)/,:y=>/(y\w*)/,:c=>/(c\w*)/}, {:s=>/(s\w*)/}].each do |set|
			set.each{ |k,v| string.gsub!(v, k.to_s) }
		end
		
		return string
	end
		
	def round_with_precision(number, precision = nil)
		precision.nil? ? number : (number * (10 ** precision)).round / (10 ** precision).to_f
	end	

	def sanitize(string)
		if string.match(/:/) && !string.match(/[a-zA-Z ]/)
			# add leading zeros where missing...
			string.gsub!(/!(\d):/, '!0\1:')
			string.gsub!(/^(\d):/, '0\1:')
			string.gsub!(/:(\d):/, ':0\1:')
			string.gsub!(/:(\d):/, ':0\1:') # needs to happen twice??
			string.gsub!(/:(\d(.\d)*)$/, ':0\1')
			
			# remove leading zero-value digitals
			string.sub!(/[0:]*/, '')
		else
			# if the string starts with a number we can assume the value-label pairs are like '10 minutes'
			if string[0,1].match(/\d/)
				string = string.split(/(!?\d[.\d]*[-_:, a-zA-Z]+)/).delete_if{|x| x == ""}.inject(String.new) { |memo, s| memo << ((s.match(/!/) || s.match(/[1-9]/)) ? s : "")  }

			# if starts with a letter we can assume the value-label pairs are like 'minutes: 10'
			else
				string = string.split(/([-A-Za-z: ,]+\d[.\d]*)/).delete_if{|x| x == ""}.inject(String.new) { |memo, s| memo << ((s.match(/!/) || s.match(/[1-9]/)) ? s : "")  }
				string.sub!(/([ ,])*([a-zA-Z]+)/, '\2')
			end
		end
		string.gsub(/!/, '')
	end
end