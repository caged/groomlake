$KCODE = 'UTF-8'
require 'iconv'
require 'base'

# Copyright (c) 2007 Active Reload, LLC.
# Parses Photoshop ACO files, version 1 and 2.
#
# Version 2 files contain version 1 information too, so some data is repeated.

module GroomLake 
  class ColorPalette < Base
    attr_reader :swatches
    
    def initialize(preset_file = nil)
      super
      @swatches = []
      
      parse_aco_file unless @io.nil?
    end
    
    def parse_aco_file
      parse_header
      parse_swatches
    end
    
    def parse_header
      @io.read(2).unpack('n')[0] # Skip version #
      @size = @io.read(2).unpack('n')[0] # How many swatches do we have
    end
    
    def parse_swatches
      version1_pos = @io.pos
      @io.read(10 * @size) # Skip all version 1 info
      unless @io.eof?
        @io.read(4) # Size repeated
        1.upto(@size) do 
          color_data = parse_color_data(@io.read(10))
          name_length = @io.read(4).unpack('xxn')[0]
          utf8_name  = @io.read(name_length * 2).unpack('C*').pack('U*')
          name = Iconv.iconv('UTF-8', 'UTF-16', utf8_name)[0].chop
          @swatches << color_data.merge(:name => name)
        end
      else
        @io.pos = version1_pos #Version 2 isn't here, go back and pick up version 1 info
        1.upto(@size) do
          @swatches < parse_color_data(@io.read(10))
        end
      end
    end
      
    def parse_color_data(d)
      space, data = d.unpack("na*")
      case space
      when 0
        space = :RGB
        data = data.unpack("nnn").collect { |c| c/256 }
      when 1
        space = :HSB
        hsb = data.unpack("nnn")
        hsb[0] = (hsb[0]/182.04).round
        hsb[1] = (hsb[1]/655.35).round
        hsb[2] = (hsb[2]/655.35).round
        data = hsb
      when 2
        space = :CMYK
        data = data.unpack("nnnn")
      when 3 then space = :Pantone
      when 4 then space = :Focoltone
      when 5 then space = :Trumatch
      when 6 then space = :Toyo88colorfinder1050
      when 7
        space = :Lab
        l = [10000, data[0,2].unpack("n")[0]].min
        a = [12700, [-12800, data[2,2].reverse.unpack("s")[0]].max].min
        b = [12700, [-12800, data[4,2].reverse.unpack("s")[0]].max].min
        data = [l, a, b]
      when 8
        space = :grayscale
        data = [10000, data.unpack("n")[0]].min
      when 10 then space = :HKS
      end
      {:space => space, :components => data}
    end
  end
end

GroomLake::ColorPalette.new('../../test/presets/oddgreen.aco')