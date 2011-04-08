require 'spec_helper'
require 'fakefs'
require 'fakefs/safe'
require 'fakefs/spec_helpers'

require File.dirname(__FILE__) + '/../lib/android_sync'

describe AndroidSync do

  include FakeFS::SpecHelpers

  def create_temporary_destination_files
    @new_destination_files = create_temporary_files(@d_files, @destination)
    @new_destination_files.should =~ Dir.glob("#{@destination}/**/*").reject { |x| File.directory?(x) }
  end

  before :each do
    @source = "/source"
    @destination = '/destination'

    FileUtils.mkdir_p @source
    FileUtils.mkdir_p @destination

    @d_files = ('x'..'z').collect { |x| "show/destination_#{x}_#{x.bytes.first}.mp3" }
    @s_files = ('a'..'g').collect { |x| "show/source_#{x}_#{x.bytes.first}.mp3" }
    @source_files = create_temporary_files(@s_files, @source)

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

  context "Using ctime sort type" do

    it "should return shows to sync", :wip2 => true do
      new_files, new_files_destination = @a.get_new_files_to_sync(@source, @destination, { :sort => { 'type' => 'ctime' }, :keep => 3 })
      new_files.should =~ get_files(@source).sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }[0...3]
      new_files_destination.should == @destination
    end

    it "should perform sync" do
      @a.perform_sync(@source, @destination, { :sort => { 'type' => 'ctime' } })
      get_files_minus_base(@destination).should =~ get_files_minus_base(@source)
    end

    describe "With existing files in destination that do not exist in source" do

      before :each do
        create_temporary_destination_files
      end

      it "should sync, leaving alone existing files in destination" do
        @a.perform_sync(@source, @destination, { :sort => { 'type' => 'ctime' }, :keep => 3 })
        get_files_minus_base(@destination).should =~ get_files_minus_base(@source).reverse[0...3].concat(@d_files).sort
      end

      it "should sync, leaving alone existing files in destination using run()" do
        @b = AndroidSync.new({ :destination => @destination, :config => write_out_temporary_yaml, :quiet => true, :forreal => true })
        @b.run
        get_files_minus_base(@destination).reverse.should =~ get_files_minus_base(@source).reverse[0...3].concat(@d_files).sort
      end
    end

    describe "With existing files in destination that exist in source" do

      before :each do
        @d_files.unshift 'show/source_d_100.mp3'
        @new_destination_files = create_temporary_files(@d_files, @destination)
        @new_destination_files.should =~ get_files(@destination)
      end

      it "should sync, leaving alone existing files in destination but clearing out some shows" do
        @a.perform_sync(@source, @destination, { :sort => { 'type' => 'ctime' }, :keep => 3 })
        @d_files.shift
        get_files_minus_base(@destination).reverse.should =~ get_files_minus_base(@source).reverse[0..3].concat(@d_files).sort
      end

      it "should sync, leaving alone existing files in destination but clearing out some shows using run()" do
        @b = AndroidSync.new({ :destination => @destination, :config => write_out_temporary_yaml, :quiet => true, :forreal => true })
        @b.run
        @d_files.shift
        get_files_minus_base(@destination).reverse.should =~ get_files_minus_base(@source).reverse[0..3].concat(@d_files).sort
      end
    end

    it "should allow a specific source label to be executed" do
      pending('to be implemented') do
      end
    end

  end

  context "Using regex sort type" do

    it "should return shows to sync", :wip => true do
      new_files, new_files_destination = @a.get_new_files_to_sync(@source, @destination, {
        :sort => { 'type' => 'regex' }, :keep => 3 }
      )
      new_files.should =~ get_files(@source).sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }[0...3]
      new_files_destination.should == @destination
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
    sleep(0.8)   # yes, this is lame, but cannot fake ctime with fakefs :(
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

def get_files(where)
  Dir.glob("#{where}/**/*").reject { |x| File.directory?(x) }
end

def get_files_minus_base(where)
  get_files(where).collect { |x| x = x.gsub(/#{Regexp.escape("#{where}/")}/, '') }
end
