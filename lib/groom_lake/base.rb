module GroomLake
  class Base    
    def initialize(preset_file = nil, opts = {})
      if preset_file != nil && File.exists?(preset_file)
        @io = File.open(preset_file)
      end
    end
  end
end