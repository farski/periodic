require File.dirname(__FILE__) + '/test_helper'

class PeriodicTest < Test::Unit::TestCase	
	context "The parser" do
		setup	do
			@units = Hash.new
			@units[:seconds] = { :value => 1, :labels => %q{ s sec second } }
			@units[:minutes] = { :value => 60, :labels => %q{ m min minute } }
			@units[:hours] = { :value => 3600, :labels => %q{ h hr hour } }
			@units[:days] = { :value => 3600*24, :labels => %q{ d day } }
			@units[:weeks] = { :value => 3600*24*7, :labels => %q{ w week } }
			@units[:months] = { :value => 3600*24*30, :labels => %q{ month } }
			@units[:years] = { :value => 3600*24*365.25, :labels => %q{ y yr year } }
			@units[:decades] = { :value => 3600*24*365.25*10, :labels => %q{ dec decade } }
			@units[:centuries] = { :value => 3600*24*365.25*100, :labels => %q{ c cn cent century centuries } }
			@units[:millennia] = { :value => 3600*24*365.25*1000, :labels => %q{ mil millennium millennia } }
		end
		
		should "return nil if the string can't be parsed" do
			assert_nil Periodic.parse('not a valid duration')
		end
		
		should "return an Integer if the result is a whole number of seconds" do
			assert_kind_of Integer, Periodic.parse('1')
			assert_kind_of Integer, Periodic.parse('1 second')
			assert_kind_of Integer, Periodic.parse('60 seconds')
			assert_kind_of Integer, Periodic.parse('1 minute')
			assert_kind_of Integer, Periodic.parse('1.5 minutes')
		end
		
		should "return a Float if the result contains partial seconds" do
			assert_kind_of Float, Periodic.parse('.1 second')
			assert_kind_of Float, Periodic.parse('99.1 seconds')
			assert_kind_of Float, Periodic.parse('1.01 minutes')
		end

		should "obey the flag to force the result to be a float" do
			assert !1.eql?(Periodic.parse('1', :seconds => :partial))
			assert !1.eql?(Periodic.parse('1.0', :seconds => :partial))
			assert 1.0.eql?(Periodic.parse('1', :seconds => :partial))
			assert 1.0.eql?(Periodic.parse('1.0', :seconds => :partial))
			assert !60.eql?(Periodic.parse('1 minute', :seconds => :partial))
			assert 60.0.eql?(Periodic.parse('1 minute', :seconds => :partial))
		end

		should "consider non-labeled numbers to be seconds" do
			assert_equal 1, Periodic.parse('1')
			assert_equal 60.5, Periodic.parse('60.5')
			assert_equal 365, Periodic.parse('365')
		end
		
		context "when given input with text labels" do
			context "with only one unit" do
				should "handle different labels and abbreviations for all supported units" do
					@units.each do |unit, data|
						data[:labels].each do |label|
							assert_equal data[:value], Periodic.parse("1#{label}")
							assert_equal data[:value], Periodic.parse("1#{label}s")
							assert_equal data[:value], Periodic.parse("1 #{label}")
							assert_equal data[:value], Periodic.parse("1 #{label}s")
						end
					end
				end
			end
			
			context "with several units" do
				should "handle different labels/abbreviations and separators" do
					assert_equal 61, Periodic.parse('1m1s')
					assert_equal 61, Periodic.parse('1 minute 1 second')
					assert_equal 61, Periodic.parse('1 minute and 1 second')
					assert_equal 61, Periodic.parse('1 minute, 1 second')
					assert_equal 3661, Periodic.parse('1 hour, 1 minute and 1 second')
					assert_equal 3661.1, Periodic.parse('1 hour, 1 minute and 1.1 seconds')
				end
				
				should "work with non-consecutive units" do
					assert_equal 3601, Periodic.parse('1 hour, 1 second')
				end
				
				should "work with every possible unit in a single string" do
					assert_equal 35063780461, Periodic.parse('1 millennia 1 century 1 decade 1 year 1 month 1 week 1 day 1 hour 1 minute 1 second')
				end
				
				should "work with every possible unit in a single string even in a random order" do
					assert_equal 35063780461, Periodic.parse('1 minute 1 second 1 millennia 1 month 1 week 1 day 1 hour 1 century 1 decade 1 year')
				end
			end

			context "with a bias" do
				should "adjust non-labeled input appropriately" do
					@units.each do |unit, data|
						assert_equal data[:value], Periodic.parse('1', :bias => unit)
					end
				end
			
				should "not break when the bias is a unit larger than the maximum unit in the input" do
					assert_equal 1, Periodic.parse('1 second', :bias => :minutes)
					assert_equal 60, Periodic.parse('1 minute', :bias => :hours)
					assert_equal 3600, Periodic.parse('1 hour', :bias => :years)
				end
			end
			
			context "even in unusual or impractical situations" do
				should "work when a smaller unit value overlaps an included larger unit" do
					assert_equal 120, Periodic.parse('01 minute 60 seconds')
				end
				
				should "work when part of a larger unit value carries down to an included smaller unit" do
					assert_equal 120, Periodic.parse('1.5 minutes 30 seconds')
				end
				
				should "work when part of a larger unit value carries down to an included smaller unit and they both include decimals" do
					assert_equal 90.1, Periodic.parse('1.5 minutes .1 seconds')
				end
			end
		end
		
		context "when given input with colon delimiters" do
			should "assume the smallest given value is in seconds" do
				assert_equal 1, Periodic.parse('0:01')
				assert_equal 1.1, Periodic.parse('0:01.1')
				assert_equal 60, Periodic.parse('1:00')
				assert_equal 61, Periodic.parse('1:01')
				assert_equal((3600*24), Periodic.parse('1:00:00:00'))
			end

			context "with a bias" do
				should "adjust correctly" do
					@units.each do |unit, data|
						assert_equal data[:value], Periodic.parse('1:00', :bias => unit) unless unit == :seconds
					end
					assert_equal 3661, Periodic.parse('01:01:01', :bias => :seconds)
					assert_equal 90060, Periodic.parse('01:01:01', :bias => :days)
				end
				
				should "not listen to the explicit bias when it is smaller than the largest unit given" do
					assert 1 != Periodic.parse('1:00', :bias => :seconds)
				end
				
				should "adjust bias to most reasonable fit when it is smaller than the largest unit given" do
					assert_equal 90, Periodic.parse('1:30', :bias => :seconds)
				end
			end
		end
	end

	context "The printer" do
		should "return nil if the arguments aren't correct" do
			assert_nil Periodic.print('foo', '%s')
			assert_nil Periodic.print(123, 'foo')
		end
		
		context "when using the format '%s'" do
			should "regurgitate the input number of seconds" do
				assert_equal '1', Periodic.print(1, '%s')
				assert_equal '60', Periodic.print(60, '%s')
				assert_equal '123456789', Periodic.print(123456789, '%s')
				assert_equal '1234.56789', Periodic.print(1234.56789, '%s')
			end
			
			should "correctly determine whether to print an integer or a float" do
				assert_equal '1', Periodic.print(1, '%s')
				assert_equal '1.0', Periodic.print(1.0, '%s')
			end

			context "with an explicitly defined precision" do
				should "print a predictable string" do
					assert_equal '1', Periodic.print(1, '%s', :precision => 0)
					assert_equal '1.0', Periodic.print(1, '%s', :precision => 1)
					assert_equal '1.0', Periodic.print(1, '%s', :precision => 2)
					assert_equal '1', Periodic.print(1.234, '%s', :precision => 0)
					assert_equal '1.2', Periodic.print(1.234, '%s', :precision => 1)
					assert_equal '1.23', Periodic.print(1.234, '%s', :precision => 2)
				end
				
				should "handle rounding correctly" do
					assert_equal '1.235', Periodic.print(1.2345, '%s', :precision => 3)
				end
			end
		end

		context "when using the default format" do
			should "handle simple, whole number inputs" do
				assert_equal '1:00', Periodic.print(60)
				assert_equal '1:00:00', Periodic.print(3600)
				assert_equal '1:00:00:00', Periodic.print(3600*24)
				assert_equal '1:00:00:00:00', Periodic.print(3600*24*7)
				assert_equal '1:00:00:00:00:00', Periodic.print(3600*24*7*4)
				assert_equal '1:00:00:00:00:00:00', Periodic.print(3600*24*7*4*52)
			end
			
			should "keep all values including and smaller than the first required value" do
				assert_equal '00:01:00:00', Periodic.print(3600, '!%d:%h:%m:%s')
				assert_equal '00:00:01:00:00', Periodic.print(3600, '%y:%n:!%w:%d:%h:%m:%s')
			end
			
			should "correctly determine whether to print a float or integer for the seconds" do
				assert_equal '1:00:00:00:00:00:00', Periodic.print(3600*24*7*4*52)
				assert_equal '1:00:00:00:00:00:00.0', Periodic.print(3600*24*7*4*52.0)
				
				assert_equal '51:00:00:21:33:09', Periodic.print(123456789)
				assert_equal '51:00:00:21:33:09.0', Periodic.print(123456789.0)
			end
		end

		context "when using a format that has text labels" do
			should "remove zero-value value-units pairs when the number comes first" do
				assert_equal '1 hours', Periodic.print(3600, '%d days %h hours %m minutes %s seconds')
				assert_equal '1 hours 1 seconds', Periodic.print(3601, '%d days %h hours %m minutes %s seconds')
				assert_equal '1 hours 0.1 seconds', Periodic.print(3600.1, '%d days %h hours %m minutes %s seconds')
			end
			
			should "remove zero-value value-units pairs when the label comes first" do
				assert_equal 'Hours: 1', Periodic.print(3600, 'Days: %d, Hours: %h, Minutes: %m, Seconds: %s')
				assert_equal 'Hours: 1, Seconds: 1', Periodic.print(3601, 'Days: %d, Hours: %h, Minutes: %m, Seconds: %s')
				assert_equal 'Hours: 1, Seconds: 0.1', Periodic.print(3600.1, 'Days: %d, Hours: %h, Minutes: %m, Seconds: %s')
			end
			
			should 'keep only those zero-value value-label pairs that are explicitly required' do
				assert_equal '1 hours 0 seconds', Periodic.print(3600, '%d days %h hours %m minutes !%s seconds')	
				assert_equal 'Hours: 1, Seconds: 0', Periodic.print(3600, 'Days: %d, Hours: %h, Minutes: %m, Seconds: !%s')
			end
			
			should "correctly determine whether to print a float or integer for the last printed value" do
				assert_equal '1 hours', Periodic.print(3600, '%d days %h hours %m minutes %s seconds')
				assert_equal '1.0 hours', Periodic.print(3600.0, '%d days %h hours %m minutes %s seconds')
				# assert_equal '1 hours 0.0 seconds', Periodic.print(3600.0, '%d days %h hours %m minutes %s seconds')	
				# assert_equal 'Hours: 1, Seconds: 0.0', Periodic.print(3600.0, 'Days: %d, Hours: %h, Minutes: %m, Seconds: %s')
			end
			
			context "with an explicitly defined precision" do
				should "work as expected" do
					assert_equal '1 hours', Periodic.print(3600, '%d days %h hours %m minutes %s seconds', :precision => 0)
					assert_equal '1.0 hours', Periodic.print(3600, '%d days %h hours %m minutes %s seconds', :precision => 1)
					assert_equal '1.0 hours', Periodic.print(3600, '%d days %h hours %m minutes %s seconds', :precision => 2)
				
					assert_equal '1 hours 30 minutes', Periodic.print(5400, '%d days %h hours %m minutes %s seconds', :precision => 0)
					assert_equal '1 hours 30.0 minutes', Periodic.print(5400, '%d days %h hours %m minutes %s seconds', :precision => 1)
				
					assert_equal '2 hours', Periodic.print(5400, '%h hours', :precision => 0)
				
					assert_equal '1 hours 1800 seconds', Periodic.print(5400, '%h hours %s seconds', :precision => 0)
					assert_equal '1 hours 1800.0 seconds', Periodic.print(5400, '%h hours %s seconds', :precision => 1)
					assert_equal '1 hours 1800.1 seconds', Periodic.print(5400.1, '%h hours %s seconds', :precision => 1)
				end
			end
		end

		context "when the input has repeating decimals" do
			should "" do
			end
		end

		should "simply regurgitate when given a value that equals the factor of the format" do
			assert_equal "1", Periodic.print((1), "%s")
			assert_equal "1", Periodic.print((60), "%m")
			assert_equal "1", Periodic.print((60*60), "%h")
			assert_equal "1", Periodic.print((60*60*24), "%d")
			assert_equal "1", Periodic.print((60*60*24*7), "%w")
		end
	end
end