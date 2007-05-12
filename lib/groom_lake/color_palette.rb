require 'base'

module GroomLake
  class ColorPalette < Base
    @swatches = []
    attr_accessor :swatches
    
    @color_spaces = {
      :RGB  => [0, 'nnn'],
      :CMYK => [2, 'nnnn']
    }
    attr_accessor :color_formats
        
    def initialize(preset_file = nil)
      super
      @header = { 
        :version => [2, 'n'], 
        :size    => [2, 'n'] 
      }
      
      @version1_swatch = {
        :space => [2, 'n'], 
        :data  => :parse_color_space
      }
      
      @version2_swatch = {
        :space => [2, 'n'],
        :data  => :parse_color_space,
        :name  => :parse_name
      }
      
      parse_aco_file unless @io.nil?
    end
    
    def parse_aco_file
      parse_header
      parse_swatches
    end
    
    def parse_header
      @io.read(@header[:version][0]).unpack(@header[:version][1])[0]
      @size = @io.read(@header[:size][0]).unpack(@header[:size][1])[0]
    end
    
    def parse_swatches
      1.upto(@size) do
        parse_color_data(@io.read(10))
      end
    end
      
    def parse_color_data(io)
      space = io.unpack('n')
      case space
        when 3 then space = 'Pantone'
        when 4 then space = 'Focaltone'
      end
    end
  end
end

GroomLake::ColorPalette.new('../../test/presets/teal1.aco')