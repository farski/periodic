require File.dirname(__FILE__) + '/test_helper'

class ParserTest < Test::Unit::TestCase	
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
		
		should "raise an error if the string can't be parsed" do
			assert_raise ArgumentError do
				Periodic.parse('contains no numbers')
			end
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
			
			context "with the last unit is unlabeled" do
				should "fall back to the bias for that unit" do
					assert_equal 61, Periodic.parse('1 minutes 1')
					assert_equal 3601, Periodic.parse('1 hours 1')
					assert_equal 3660, Periodic.parse('1 hours 1', :bias => :minutes)
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
end