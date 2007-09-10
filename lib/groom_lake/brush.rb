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
      parse! unless @io.nil?
    end
    
    def parse!
      parse_header
      parse_brushes
    end
    
    def parse_header
      @version = @io.read(2).unpack('n')[0]
      if(@version == 6) 
        @subversion = @io.read(2).unpack('n')[0]
      else
        @brush_count = @io.read(2).unpack('n')[0]
      end
    end
    
    def parse_brushes
      case @version
      when 6
       parse_version_six
      when 2
        parse_version_one_or_two
      end
    end
    
    def parse_version_one_or_two
      puts "VERSION 2"
      puts '-' * 100
      
      1.upto(@brush_count) do
        
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
            brush_height.times do 
              scanline_image = scanline_image + @io.read(2).unpack('n')[0]
            end
            puts "SCI: #{scanline_image}"
            scan = @io.read(scanline_image)
            write_image(name, brush_width, brush_height, scan)
          end
        end
      end
    end
    
    def parse_version_six
        @io.read(4) # Begin 8BIM tag
        type = @io.read(4) # [samp|pat|desc]
        
        sample_size = @io.read(4).unpack('N')[0]
        puts "SSIZE: #{sample_size}"
        sample_end = sample_size + 12
        puts "POS: #{@io.pos}, SAMP: #{sample_end}"
        
        while(@io.pos < sample_end - 1)
          #brush size in bytes
          brush_size = @io.read(4).unpack('N')[0]
          brush_end = brush_size
          puts "BRUSH SIZE: #{brush_size}"
          while(brush_end % 4 != 0) 
            brush_end += 1
          end
          offset = brush_end - brush_size
          puts "FBC: #{offset}"
          key = @io.read(37)
          # name_length = @io.read(4).unpack('xxn')[0]
          
          puts "key: #{key}"
          
          if @subversion == 1
            puts 'yeah'
          elsif @subversion == 2
            @io.pos += 264
            padh, padw = @io.read(8).unpack('NN')
            puts "W: #{padw}, H: #{padh}"
            height, width = @io.read(8).unpack('NN')
            width -= padw
            height -= padh
          end
          
          depth = @io.read(2).unpack('n')[0]
          puts "DEPTH: #{depth}"
          compression = @io.read(1).unpack('b')[0]
          
          scanline_image = 0
          height.times do 
            scanline_image = scanline_image + @io.read(2).unpack('n')[0]
          end
          scan = @io.read(scanline_image)
          
          puts "FINAL #{@io.pos}"
          #write_image(Time.now.to_s + @io.pos.to_s + 'brush', width, height, scan)
          
          # @io.read(offset) if @subversion == 1
          # if(@subversion == 2)
          #   @io.read(8)
          #   @io.read(offset)
          # end
        end
        
        puts @io.readchar
        
        
        
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
    
    def write_image(name, width, height, scanline_data)
      img = Magick::Image.new(width, height)
      unpacked_data = unpack_scanline_data(scanline_data)
      img.import_pixels(0, 0, width, height, "A", unpacked_data, Magick::CharPixel)
      img.format = "PNG"
      img = img.colorize(1, 1, 1, '#000000')
      img.write('../../vendor/' + name.downcase + ".png")
    end
    
  end
end

GroomLake::Brush.new('../../test/presets/scary-girl.abr')
#GroomLake::Brush.new('../../test/presets/cs2-square-brushes.abr')
#GroomLake::Brush.new('../../test/presets/onesquare24hard.abr')
#GroomLake::Brush.new('../../test/presets/cs2-oldbooks.abr')