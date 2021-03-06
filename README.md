# Periodic

[![Gem Version](http://img.shields.io/gem/v/periodic.svg)](https://rubygems.org/gems/periodic)
[![Dependency Status](https://gemnasium.com/farski/periodic.svg)](https://gemnasium.com/farski/periodic)
[![Build Status](https://travis-ci.org/farski/periodic.svg)](https://travis-ci.org/farski/periodic)
[![Code Climate](https://codeclimate.com/github/farski/periodic/badges/gpa.svg)](https://codeclimate.com/github/farski/periodic)
[![Coverage Status](https://coveralls.io/repos/farski/periodic/badge.svg)](https://coveralls.io/r/farski/periodic)

## Usage

#### Parser

Periodic will parse out natural language strings representing durations using different units of time, and return the total number of seconds. When using text labels, it will do it's best to look for any of the following units: seconds, minutes, hours, days, weeks, months, years, decades, centuries, millennia. Units can appear in any order in the string, and may appear more than once.

When using a digital format (e.g. 10:30), the parser will default to the smallest sensible units (e.g. 10 minutes 30 seconds), but this can be overridden using the :bias option (e.g. :bias => centuries, 10 centuries 30 decades). Valid options for the :bias are symbols of those units mentioned in the previous paragraph. If a bias is explicitly defined that is too precise for the given string, the smallest sensible unit will be substituted

    >> Periodic.parse('1 minute')
    => 60
    >> Periodic.parse('60min')
    => 3600
    >> Periodic.parse('1:30')
    => 90
    >> Periodic.parse('1:30', :bias => :hours)
    => 5400

#### Formatting

The #format method of Periodic::Duration objects lets you format the number of seconds into different units. Any combination of units can be used to express precise values, the the precision is optioned (i.e. 90 seconds can be output as '1 minute' or '1.5 minutes', or '1 minute 30 seconds'). If you use text labels in the format, they can come either before or after the values, and in both cases the resulting string by default will have zero-value value-label pairs removed (e.g. with a value of 30, and a format of '%m minute %s seconds', by default it will print '30 seconds', not '0 minutes 30 seconds'). Pairs can be forced into the result with a '!' before the directive. When using a digital format (like the default '%y:%d:%h:%m:%s'), you should be sure to include all directives between the largest and smallest unit, though it will work even with missing directives.

The available directives
/%s/, /%m/, /%h/, /%d/, /%y/

    >> Duration.new(125).format
    => '2:05'
    >> Duration.new(125).format('%y:%d:!%h:%m:%s')
    => '00:02:05'
    >> Duration.new(125).format('%h hours %m minutes %s seconds')
    => '2 minutes 5 seconds'
    >> Duration.new(125).format('!%h hours %m minutes %s seconds')
    => '0 hours 2 minutes 5 seconds'
    >> Duration.new(125).format('!%h hours %s seconds')
    => '0 hours 125 seconds'

### TODO
- plural text labels should automatically be singularized with 1

## COPYRIGHT

Copyright (c) 2016 Chris Kalafarski. See LICENSE for details.
