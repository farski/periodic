module Periodic
  module Parser
    def parse(string, options = { :bias => :seconds})
      return Parseable.new(string, options[:bias]).seconds
    end

    private

    class  Parseable
      def initialize(string, bias)
        @string = string
        validates_inclusion_of_numeral_in_string
        @bias = bias

        extract_time_parts_from_string
      end

      def seconds
        units = { :seconds => 1, :minutes => 60, :hours => 3600, :days => 3600*24, :weeks => 3600*24*7, :months => 3600*24*30, :years => 3600*24*365.25, :decades => 3600*24*365.25*10, :centuries => 3600*24*365.25*100, :millennia => 3600*24*365.25*1000 }
        seconds = @time_parts.inject(0) { |total, part| total = total + (part[1] * units[part[0]]) }
        return seconds % 1 == 0 ? seconds.to_i : seconds
      end

      private

      def validates_inclusion_of_numeral_in_string
        raise ArgumentError, "String contains no numbers", caller unless @string.match(/\d/)
      end

      def digital?
        @string.match(/:/)
      end

      def extract_time_parts_from_string
        @time_parts = Hash.new
        digital? ? extract_time_parts_from_digital : extract_time_parts_from_text
      end

      def extract_time_parts_from_digital
        units = [:seconds, :minutes, :hours, :days, :weeks, :months, :years, :decades, :centuries, :millennia]
        @string.split(":").reverse.each_with_index do |part, i|
          @time_parts[units[i + ((units.index(@bias) >= @string.split(":").size) ? units.index(@bias) - @string.split(":").size + 1 : 0)]] = part.to_f
        end
      end

      def extract_time_parts_from_text
        normalize_string
        units = { :s => :seconds, :m => :minutes, :h => :hours, :d => :days, :w => :weeks, :n => :months, :y => :years, :a => :decades, :c => :centuries, :b => :millennia }
        @string.split(' ').each { |part| @time_parts[part.match(/([a-z])/) ? units[part.match(/([a-z])/)[1].to_sym] : @bias] = (@time_parts[part.match(/([a-z])/) ? units[part.match(/([a-z])/)[1].to_sym] : @bias]||0) + part.to_f }
      end

      def normalize_string
        [/( )/, /(,)/, /(and)/].each{ |m| @string.gsub!(m, '') }
        @string.gsub!(/(\d)([a-zA-Z]+)/, '\1\2 ')
        [{:n=>/(mo\w*)/,:b=>/(m\w*l\w*)/,:a=>/(d\w*c\w*)/}, {:m=>/(m\w*)/,:h=>/(h\w*)/,:d=>/(d\w*)/,:w=>/(w\w*)/,:y=>/(y\w*)/,:c=>/(c\w*)/}, {:s=>/(s\w*)/}].each { |set| set.each{ |k,v| @string.gsub!(v, k.to_s) } }
      end
    end
  end
end
