$KCODE = 'UTF-8'
require 'rubygems'
require 'RMagick'
require 'iconv'
require 'base'
require 'stringio'

module GroomLake 
  class Brush < Base
    def initialize(preset_file = nil)
      super
      @version = nil
      @subversion = nil
      parse_abr_file unless @io.nil?
    end
    
    def parse_abr_file
      parse_header
      parse_brushes
    end
    
    def parse_header
      
    end
    
    def parse_brushes
      @version = @io.read(2).unpack('n')[0]
      case @version
      when 6
        @subversion = @io.read(2).unpack('n')[0]
        @io.read(8) #8BIMsamp
        sample = @io.read(4).unpack('N')[0]
        endsample = sample + 12
        while(@io.pos < endsample - 1)
          #brush size in bytes
          brush_size = @io.read(4).unpack('N')[0]
          brush_end = brush_size
          
          while(brush_end % 4 != 0) 
            brush_end += 1
          end
          four_byte_compliment = brush_end - brush_size
          key = @io.read(36 * 2).unpack('C')[0]

          if @subversion == 1
            puts 'yeah'
          elsif @subversion == 2
            @io.pos += 264
            padw, padh = @io.read(8).unpack('nn')
            height, width = @io.read(8).unpack('xxNxxN')
            # puts @io.read(4).unpack('n')
            # puts @io.read(4).unpack('n')
            # puts @io.read(4).unpack('N')
            # puts @io.read(4).unpack('N')
            
          end
          return
        end
        
      when 2
        brush_count = @io.read(2).unpack('n')[0]
        puts brush_count
        1.upto(brush_count) do
          
          #Brush type, 1 = computed, 2 = sampled
          type = @io.read(2).unpack('n')[0]
          
          #Number of bytes in the remainder of the brush definition
          brush_bytes = @io.read(4).unpack('N')
          
          if type == 1
            @io.read(14) if @version == 1
          elsif type == 2
            @io.read(4) # Misc ignored
            
            #brush spacing
            spacing = @io.read(2).unpack('n')
            puts "SPACING: #{spacing}"
            
            # Length of the brush name
            name_length = @io.read(4).unpack('xxn')[0]
            
            #read it and convert it to utf-8
            utf8_name  = @io.read(name_length * 2).unpack('C*').pack('U*')
            name = Iconv.iconv('UTF-8', 'UTF-16', utf8_name)[0].chop
            puts name
            @io.read(1) # Oh noez, the forgotton byte
            
            top, left, bottom, right = @io.read(8).unpack('nnnn')
            
            #long integer version of numbers above
            ltop, lleft, lbottom, lright = @io.read(16).unpack('NNNN')

            brush_width = lright - lleft
            brush_height = lbottom - ltop
            
            puts brush_width
            puts brush_height
            
            depth = @io.read(2).unpack('n')[0]
            puts "DEPTH: #{depth}"
            compression = @io.read(1).unpack('b')[0]
            puts "COMPRESSION: #{compression}"
            
            if compression == 0
              decompression_data = @io.read(brush_width * brush_height)
            else
              puts "HEIGHT: #{brush_height}"
              scanline_image = 0
              puts @io.pos
              brush_height.times do 
                scanline_image = scanline_image + @io.read(2).unpack('n')[0]
              end
              puts "SCI: #{scanline_image}"
              scan = @io.read(scanline_image)
              img = Magick::Image.new(brush_width, brush_height)
              unpacked_data = unpack_scanline_data(scan)
              img.import_pixels(0, 0, brush_width, brush_height, "A", unpacked_data, Magick::CharPixel)
              img.format = "PNG"
              img = img.colorize(1, 1, 1, '#000000')
              img.write('../../vendor/' + name.downcase + ".png")
            end
          end
        end
      end
    end
    
    # Unpack a scanline image using the PackBits algorithm.
    def unpack_scanline_data(data)
      str = StringIO.new(data)
      image = []
      until str.eof?
        count = str.readchar
        count = -256 + count if(count >= 128) 
        if(count >= 0)
          continue if(count == -128)
          (count + 1).times do  
            image << str.readchar
          end
        else
          copy = str.readchar
          count = -count + 1
          count.times do
            image << copy 
          end
        end          
      end
      return image
    end
    
  end
end

#GroomLake::Brush.new('../../test/presets/three-various-brushes.abr')
#GroomLake::Brush.new('../../test/presets/cs2-square-brushes.abr')
#GroomLake::Brush.new('../../test/presets/onesquare24hard.abr')
GroomLake::Brush.new('../../test/presets/cs2-oldbooks.abr')