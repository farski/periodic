require 'bigdecimal'

module Periodic	
	module Duration
		module Units
			TIME = Hash.new
			TIME[:seconds] = { :factor => 1, :directive => /%s/ }
			TIME[:minutes] = { :factor => 60, :directive => /%m/ }
			TIME[:hours] = { :factor => 3600, :directive => /%h/ }
			TIME[:days] = { :factor => 3600*24, :directive => /%d/ }
			# TIME[:weeks] = { :factor => 3600*24*7, :directive => /%w/ }
			# TIME[:months] = { :factor => 3600*24*30, :directive => /%n/ }
			TIME[:years] = { :factor => 3600*24*365, :directive => /%y/ }
			
			TIME_ORDER = [:seconds, :minutes, :hours, :days, :years] # not working with weeks and months...
		end
		
		def self.sanitize_formatted_string(string)
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
				if string[0,1].match(/\d/) || string[0,1] == "!"
					string = string.split(/(!?\d[.\d]*[-_:, a-zA-Z]+)/).delete_if{|x| x == ""}.inject(String.new) { |memo, s| memo << ((s.match(/!/) || s.match(/[1-9]/)) ? s : "")  }

				# if starts with a letter we can assume the value-label pairs are like 'minutes: 10'
				else
					string = string.split(/([-A-Za-z: ,]+\d[.\d]*)/).delete_if{|x| x == ""}.inject(String.new) { |memo, s| memo << ((s.match(/!/) || s.match(/[1-9]/)) ? s : "")  }
					string.sub!(/([ ,])*([a-zA-Z]+)/, '\2')
				end
			
				# remove leading zero-value digitals
				string.sub!(/[0:]*/, '')
			end
			string.strip.gsub(/!/, '')
		end
		
		class Duration
			def initialize(seconds)
				@seconds = (seconds.is_a?(Float) ? seconds.to_f : seconds)
			end
			
			def format(format = '%y:%d:%h:%m:%s', precision = nil)
				string, nondirective_units, values, smallest_unit_directive = format, [], Hash.new, nil
				
				Periodic::Duration::Units::TIME_ORDER.reverse.each_with_index do |unit, i|
					if format =~ Periodic::Duration::Units::TIME[unit][:directive]
						values[unit] = send(unit) + nondirective_units.inject(0) { |total, u| total += (send(u) * (Periodic::Duration::Units::TIME[u][:factor] / Periodic::Duration::Units::TIME[unit][:factor])) }
						smallest_unit_directive = unit
						nondirective_units.clear
					else
						nondirective_units << unit if (send(unit) > 0)
					end
					
					# correct for any left over time that's is fractional for all the included units
					values[smallest_unit_directive] += nondirective_units.inject(0) { |total, u| total += (send(u).to_f * Periodic::Duration::Units::TIME[u][:factor] / Periodic::Duration::Units::TIME[smallest_unit_directive][:factor]) } if (!Periodic::Duration::Units::TIME_ORDER.reverse[i+1] && !nondirective_units.empty?)
				end
				
				values[smallest_unit_directive] = case precision
					when nil then (values[smallest_unit_directive] % 1 == 0) && !@seconds.is_a?(Float) ? values[smallest_unit_directive].to_i : values[smallest_unit_directive]
					when 0 then values[smallest_unit_directive].to_i
					else (values[smallest_unit_directive] * (10 ** precision)).round / (10 ** precision).to_f
				end
				
				return Periodic::Duration.sanitize_formatted_string(values.inject(string) { |str, data| str.sub!(Periodic::Duration::Units::TIME[data[0]][:directive], data[1].to_s) })
			end
			
			Periodic::Duration::Units::TIME_ORDER.each_with_index do |unit, i|
				define_method("in_" + unit.to_s) { @seconds.to_f / Periodic::Duration::Units::TIME[unit][:factor] }
				define_method("whole_" + unit.to_s) { (@seconds.to_f / Periodic::Duration::Units::TIME[unit][:factor]).floor }
				define_method(unit) { ((Periodic::Duration::Units::TIME_ORDER[i+1] ? BigDecimal.new(@seconds.to_f.to_s) % BigDecimal.new(Periodic::Duration::Units::TIME[Periodic::Duration::Units::TIME_ORDER[i+1]][:factor].to_f.to_s) : @seconds.to_f) / Periodic::Duration::Units::TIME[unit][:factor].to_f).send(unit == :seconds ? :to_f : :floor) }
			end
		end
	end
end

puts Periodic::Duration::Duration.new(60).format('!%y years %d days %h hours %m minutes %s seconds')