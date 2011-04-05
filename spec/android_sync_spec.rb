require 'spec_helper'
require 'fakefs'
require 'fakefs/safe'
require 'fakefs/spec_helpers'

require File.dirname(__FILE__) + '/../lib/android_sync'

describe AndroidSync do

  include FakeFS::SpecHelpers

  before :each do

    @source = "/source"
    @destination = '/destination'

    FileUtils.mkdir_p @source
    FileUtils.mkdir_p @destination

    @s_files = [
      "show/a.mp3",
      "show/and/some/other/directory/g.mp3",
      "show/b.mp3",
      "show/c.mp3",
      "show/d.mp3",
      "show/e.mp3",
      "show/f.mp3",
      "show/g.mp3"
    ]

    @source_files = create_temporary_files(@s_files, @source)
    
    @d_files = [
      "show/x.mp3",
      "show/y.mp3",
      "show/z.mp3"
    ]

    FakeFS.deactivate!
    opts = {
      :destination => @destination,
      :quiet => true,
      :forreal => true
    }

    @a = AndroidSync.new(opts)
    FakeFS.activate!

  end

  it "should raise Exception 'Destination must be defined' when initialised without options" do
    lambda {  AndroidSync.new }.should raise_exception('Destination must be defined')
  end

  it "should return shows to copy from source to destination, keeping last three shows" do
    new_files, new_files_destination = @a.get_new_files_to_sync(@source, @destination, 3)
    source_files = Dir.glob("#{@source}/**/*").reject { |x| File.directory?(x) }.sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }
    new_files.should =~ source_files[0...3]
    new_files_destination.should == @destination
  end

  it "should copy shows in source to destination" do
    @a.perform_sync(@source, @destination)

    destination_files = Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }.collect { |x| x = x.gsub(/#{Regexp.escape("#{@destination}/")}/, '') }
    source_files = Dir.glob("#{@source}/**/*").reject { |x| File.directory?(x) }.collect { |x| x = x.gsub(/#{Regexp.escape("#{@source}/")}/, '') }

    destination_files.should =~ source_files
  end

  describe "With existing files in destination that do not exist in source" do

    before :each do
      @new_destination_files = create_temporary_files(@d_files, @destination)
      @new_destination_files.should =~ Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }
    end

    it "should sync shows from source into destination, leaving alone existing files in destination" do

      @a.perform_sync(@source, @destination, 3)

      destination_files = Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }.collect { |x| x = x.gsub(/#{Regexp.escape("#{@destination}/")}/, '') }
      source_files = Dir.glob("#{@source}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@source}/")}/, '') }

      destination_files.should =~ source_files[0...3].concat(@d_files).sort
    end

    it "should sync shows from source into destination, leaving alone existing files in destination using run()" do

      opts = {
        :destination => @destination,
        :config => write_out_temporary_yaml,
        :quiet => true,
        :forreal => true
      }

      @b = AndroidSync.new(opts)
      @b.run

      destination_files = Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@destination}/")}/, '') }
      source_files = Dir.glob("#{@source}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@source}/")}/, '') }

      destination_files.should =~ source_files[0...3].concat(@d_files).sort
    end

  end

  describe "With existing files in destination that exist in source" do

    before :each do
      @d_files.unshift 'show/d.mp3'
      @new_destination_files = create_temporary_files(@d_files, @destination)
      @new_destination_files.should =~ Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }
    end

    it "should sync shows from source into destination, leaving alone existing files in destination but clearing out some shows" do

      destination_files = Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@destination}/")}/, '') }
      source_files = Dir.glob("#{@source}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@source}/")}/, '') }

      @a.perform_sync(@source, @destination, 3)

      destination_files = Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@destination}/")}/, '') }
      source_files = Dir.glob("#{@source}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@source}/")}/, '') }

      @d_files.shift
      destination_files.should =~ source_files[0..3].concat(@d_files).sort
    end

    it "should sync shows from source into destination, leaving alone existing files in destination but clearing out some shows using run()" do

      opts = {
        :destination => @destination,
        :config => write_out_temporary_yaml,
        :quiet => true,
        :forreal => true
      }

      @b = AndroidSync.new(opts)
      @b.run

      destination_files = Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@destination}/")}/, '') }
      source_files = Dir.glob("#{@source}/**/*").reject { |x| File.directory?(x) }.reverse.collect { |x| x = x.gsub(/#{Regexp.escape("#{@source}/")}/, '') }

      @d_files.shift
      destination_files.should =~ source_files[0..3].concat(@d_files).sort
    end
        
  end

  after :each do
    [ @source, @destination ].each { |x| y = x.gsub(/(^\/*|\/*$)/, '').split(/\//).shift ; FileUtils.rm_rf "/#{y}" if y }
  end

end

def create_temporary_files(destination_files, destination)

  files = destination_files.collect { |x| x = "#{destination}/#{x}" }.each do |f|
    file = File.new(f, 'w')
    file.write('0' * (rand(500) + 500))
    file.close
    sleep(0.6)   # yes, this is lame, but cannot fake ctime any other way :(
  end

  files

end

def write_out_temporary_yaml()

  android_sync_yaml_data = <<-eos
sources:
  - label: Test
    source: '/source/show'
    destination: "\#{destination_base}/show"
    keep: 3
    eos

  android_sync_yaml = '/tmp/android_sync.yml'

  f = File.new(android_sync_yaml, 'w');
  f.write(android_sync_yaml_data)
  f.close

  android_sync_yaml
end