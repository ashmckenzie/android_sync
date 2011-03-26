require 'yaml'
require 'fileutils'
require 'pp'

class String

  def trim(chars)
    self.gsub(/#{chars}*$/, '')
  end

end

class AndroidSync

  attr_accessor :debug, :verbose, :pretend

  # The default YAML configuration file
  #
  DEFAULT_CONFIG = File.dirname(__FILE__) + '/../android_sync.yml'

  # Pretend / dry-run mode
  #
  DEFAULT_PRETEND = false

  DEFAULT_VERBOSE = true
  DEFAULT_DEBUG = false

  def initialize(opts = {})  # :nodoc:

    raise Exception, 'Destination must be defined' unless opts[:destination]

    @destination_base = opts[:destination]

    @config_file = opts[:config] ? opts[:config] : DEFAULT_CONFIG

    raise Exception, 'Config file not found' unless File.exists?(@config_file)

    @pretend = ! opts[:pretend].nil? ? opts[:pretend] : DEFAULT_PRETEND
    @verbose = ! opts[:verbose].nil? ? opts[:verbose] : DEFAULT_VERBOSE
    @debug = ! opts[:debug].nil? ? opts[:debug] : DEFAULT_DEBUG

    @config = YAML.load_file(@config_file)

    @source = nil
    @destination = nil
    
    @new_files = []
    @new_files_destination = []

  end

  # Sync a bunch of stuff to an Android device (essentially a mounted volume)
  #
  def run
    puts
    @config['sources'].each do |s|
      puts "- Looking at #{s['label']}"
      perform_sync(s['source'], s['destination'], s['keep'])
      puts
    end
  end

  def perform_sync(source, destination, keep=nil)
    @new_files, @new_files_destination = get_new_files_to_sync(source, destination, keep)
    sync_new_files
    cleanup_files_we_dont_want_to_keep unless keep.nil?
  end

  def get_new_files_to_sync(source, destination, keep=nil)

    @source = source
    @destination = destination

    # This variable is eval'd using entries setup in the YAML file
    #
    destination_base = @destination_base.trim('/')

    new_files_destination = eval('"' + destination + '"').trim('/')

    all_new_files = Dir.glob("#{source.trim('/')}/**/*").reject { |x| File.directory?(x) }.sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }

    unless keep.nil?
      new_files = all_new_files[0...keep]
    else
      new_files = all_new_files
    end

    [ new_files, new_files_destination ]

  end

  private

  def sync_new_files

    new_files_destination_parent = '/' + @new_files_destination.split(/\//)[-2]

    raise "Base destination directory '#{new_files_destination_parent}' does not exist" unless File.directory?(new_files_destination_parent)

    puts "DEBUG: new_files_destination_parent=[#{new_files_destination_parent}]" if @debug

    Dir.mkdir(@new_files_destination) if ! File.directory?(@new_files_destination) and ! @pretend

    @new_files.each do |file|
      destination_file = "#{@new_files_destination}/#{file.gsub(/#{Regexp.escape("#{@source}/")}/, '')}"
      next if File.exists?(destination_file)
      puts "+ Copying '#{File.basename(file)}' to '#{destination_file}'" if @verbose
      puts "DEBUG: Copying '#{file} to '#{destination_file}'" if @debug
      FileUtils.cp(file, destination_file) unless @pretend
    end

  end

  def cleanup_files_we_dont_want_to_keep

    existing_files = Dir.glob("#{@new_files_destination}/**/*").reject { |x| File.directory?(x) }.sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }.reject do |file|
      @new_files.collect { |x| File.basename(x) }.include?(File.basename(file))
    end

    existing_files.each do |file|
      puts "! Removing '#{file}'" if @verbose
      FileUtils.rm_f(file) unless @pretend
    end

  end

end
