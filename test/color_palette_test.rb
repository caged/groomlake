$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib', 'groom_lake')
require 'groom_lake'

require 'test/unit'
require 'rubygems'
require 'test/spec'

context "Parsing Photoshop ACO Files" do
  
  specify "Should get swatches from file" do
    aco = GroomLake::ColorPalette.new('presets/teal1.aco')
    aco.swatches[0].should == {:components => [0, 153, 153], :name => "Teal", :space => :RGB}
  end
  
  specify "Should correctly parse HSB space" do 
    aco = GroomLake::ColorPalette.new('presets/oddgreen.aco')
    aco.swatches[0].should == {:name=>"OddGreen", :components=>[106, 71, 66], :space=>:HSB}
  end
  
end