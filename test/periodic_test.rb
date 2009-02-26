require File.dirname(__FILE__) + '/test_helper'

class PeriodicTest < Test::Unit::TestCase
	context "The parser" do
		should "return nil if the string can't be parsed" do
			assert_nil Periodic.parse('not a valid duration')
		end
		
		should "return an integer if there are no partial seconds" do
			assert_kind_of Integer, Periodic.parse('1 second')
			assert_kind_of Integer, Periodic.parse('1 minute')
			assert_kind_of Integer, Periodic.parse('1.0 minute')
			assert_kind_of Integer, Periodic.parse('1.25 minutes')
			assert_kind_of Integer, Periodic.parse('1 minute 1 second')
			assert_kind_of Integer, Periodic.parse('1.25 minutes 1 second')
		end
		
		should "return a float is there are partial seconds" do
			assert_kind_of Float, Periodic.parse('.1 second')
			assert_kind_of Float, Periodic.parse('0.1 second')
			assert_kind_of Float, Periodic.parse('1.01 minutes')
			assert_kind_of Float, Periodic.parse('1 minute 0.1 second')
		end
		
		should "parse solitary numbers into seconds without labels" do
			assert_equal 1, Periodic.parse('1')
			assert_equal 1, Periodic.parse('1.0')
			assert !1.eql?(Periodic.parse('1.0', :seconds => :partial))
			assert 1.0.eql?(Periodic.parse('1.0', :seconds => :partial))
		end
		
		should "parse solitary numbers appropriately with a bias" do
			assert_equal 60, Periodic.parse('1', :bias => :minutes)
			assert_equal 3600, Periodic.parse('1', :bias => :hours)
			assert_equal((3600*24*365.25), Periodic.parse('1', :bias => :years))
			assert_equal((3600*24*365.25*100), Periodic.parse('1', :bias => :centuries))
		end
		
		should "correctly parse labeled numbers that are below the bias" do
			assert_equal 1, Periodic.parse('1s', :bias => :minutes)
			assert_equal 60, Periodic.parse('1minute', :bias => :hours)
		end
		
		context "with text labels" do
			context "with a single unit" do
				should "parse seconds with a variety of labels" do
					%q{s sec secs second seconds}.each do |l|
						assert_equal(1, Periodic.parse('1' + l))
						assert_equal(1, Periodic.parse('1 ' + l))
					end
					assert !1.eql?(Periodic.parse('1.0 second', :seconds => :partial))
					assert 1.0.eql?(Periodic.parse('1.0 second', :seconds => :partial))
				end
		
				should "parse minutes with a variety of labels" do
					%q{m min mins minute minutes}.each do |l|
						assert_equal(60, Periodic.parse('1' + l))
						assert_equal(60, Periodic.parse('1 ' + l))
					end
				end
		
				should "parse hours with a variety of labels" do
					%q{h hs hr hrs hour hours}.each do |l|
						assert_equal(3600, Periodic.parse('1' + l))
						assert_equal(3600, Periodic.parse('1 ' + l))
					end
				end
			end
			
			context "with several units" do
				should "parse with a variety of labels and separators" do
					assert_equal 61, Periodic.parse('1m1s')
					assert_equal 61, Periodic.parse('1 minute 1 second')
					assert_equal 61, Periodic.parse('1 minute and 1 second')
					assert_equal 61, Periodic.parse('1 minute, 1 second')
					assert_equal 3661, Periodic.parse('1 hour, 1 minute and 1 second')
					assert_equal 3661.1, Periodic.parse('1 hour, 1 minute and 1.1 seconds')
				end
				
				should "parse even in unusual situations" do
					assert_equal 120, Periodic.parse('01 minute 60 seconds')
					assert_equal 120, Periodic.parse('1.5 minutes 30 seconds')
					assert_equal 90.1, Periodic.parse('1.5 minutes .1 seconds')
				end
			end
		end
		
		context "with symbol delimiters" do
			should "parse basic formats" do
				assert_equal 90, Periodic.parse('1:30')
				assert_equal 90.1, Periodic.parse('1:30.1')
				assert_equal 60, Periodic.parse('1:00')
			end
			
			should "parse with a bias" do
				assert_equal 5400, Periodic.parse('1:30', :bias => :hours)
			end
			
			should "parse with a bias but also correct any impossibilities" do
				assert_equal 90, Periodic.parse('1:30', :bias => :seconds) # will correct to :bias => minutes
			end
		end
	end

	context "The printer" do
		should "return nil if the arguments aren't correct" do
			assert_nil Periodic.output('foo', '%s')
			assert_nil Periodic.output(123, 'foo')
		end
		
		should "return the exact number of seconds input" do
			assert_equal "1234", Periodic.output(1234, "%s")
			assert_equal "1234.1", Periodic.output(1234.1, "%s", :exact) # this should really work w/o explicit :exact
			assert_equal "57:00", Periodic.output(3420.0)
		end
		
		should "simplify the default format as much as possible" do
			assert_equal "1", Periodic.output(1)
			assert_equal "1.1", Periodic.output(1.1)
		end
		
		should "print simple 'conversions'" do
			assert_equal "1", Periodic.output((60*60), "%h")
			assert_equal "1", Periodic.output((60*60*24), "%d")
			assert_equal "1", Periodic.output((60*60*24*7), "%w")
		end
		
		should "print text without extraneous bits" do
			assert_equal "1h", Periodic.output((60*60), "%hh %ss")
		end
		
		should "print text with forced extraneous bits" do
			assert_equal "1h 0s", Periodic.output((60*60), "%hh %s!s")
		end
		
		should "print digital without extraneous bits" do
			assert_equal "1:00:00", Periodic.output((60*60), "%d:%h:%m:%s")
		end
		
		should "print digital with forced extraneous bits" do
			assert_equal "00:01:00:00", Periodic.output((60*60), "!%d!:%h:%m:%s")
		end
	end

	context "The program" do
		should "maintain integrity throughout parsing and printing" do
			assert_equal 120, Periodic.parse(Periodic.output(Periodic.parse('2 minutes'), '%s'))
			assert_equal "120", Periodic.output(Periodic.parse(Periodic.output(120, '%s')), '%s')
			assert_equal "24:00:01", Periodic.output(Periodic.parse(Periodic.output(86401, '%h:%m:%s')), '%h:%m:%s')
		end
		
		should "not have roudning errors in this particular case" do
			assert_equal '1 hours 7 minutes 45 seconds', Periodic.output(Periodic.parse('67min 45sec', :bias => :minutes), '%h hours %m minutes %s seconds')
			assert_equal '30 minutes 1.1 seconds', Periodic.output(Periodic.parse('30min 1.1sec', :bias => :minutes), '%h hours %m minutes %s seconds')
		end
	end
end